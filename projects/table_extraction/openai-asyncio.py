import asyncio, pathlib, base64, io, os
import aiosqlite, fitz
from PIL import Image, ImageOps
from openai import AsyncOpenAI


from dotenv import load_dotenv

## loads the .env file with OPENAI_API_KEY set
load_dotenv('/home/jupyter/.env')

import openai

from agents import set_tracing_export_api_key
import importlib.metadata

print(f"openai version: {openai.__version__}")
print(f"agents version: {importlib.metadata.version('openai-agents')}")

# Must-have to ensure trace reporting
set_tracing_export_api_key(os.environ['OPENAI_API_KEY'])
DEFAULT_MODEL = 'gpt-4.1-2025-04-14'


ROOT = pathlib.Path("/home/jupyter")
DB = ROOT / "answers.sqlite3"

client = AsyncOpenAI() # uses OPENAI_API_KEY env var

# — 1. RENDER PDF PAGE
def render_page(pdf_path, page_no, dpi=200):
    doc = fitz.open(pdf_path)
    page = doc.load_page(page_no)
    pix = page.get_pixmap(dpi=dpi)
    data = pix.tobytes("png")         # PNG bytes
    doc.close()
    return data


# — 2. HIGH-CONTRAST FILTER
def contrast_png(png_bytes):
    with Image.open(io.BytesIO(png_bytes)) as img:
        high = ImageOps.autocontrast(img)
        buf = io.BytesIO()
        high.save(buf, format="PNG")
        return buf.getvalue()


# — 3. ASK OPENAI VISION MODEL
async def table_difficulty(png_bytes):
    b64 = base64.b64encode(png_bytes).decode()
    resp = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "user", "content": [
                {"type": "text", "text": "Use one word to rate the difficulty of extracting the table from this picture using easy, medium, hard?"},
                {"type": "image_url",
                 "image_url": {"url": f"data:image/png;base64,{b64}"}}
            ]}
        ]
    )
    return resp.choices[0].message.content.strip()


# — 4. PIPELINE STAGES AS COROUTINE WORKERS —
async def render_worker(in_q, out_q):
    loop = asyncio.get_running_loop()
    while task := await in_q.get():
        pdf_path, page_no = task
        png = await loop.run_in_executor(None, render_page, pdf_path, page_no)
        await out_q.put((pdf_path, page_no, png))
        in_q.task_done()


async def contrast_worker(in_q, out_q):
    while item := await in_q.get():
        pdf_path, page_no, png = item
        high_png = await asyncio.to_thread(contrast_png, png)
        await out_q.put((pdf_path, page_no, high_png))
        in_q.task_done()

        
async def openai_worker(in_q, db_q):
    while item := await in_q.get():
        pdf_path, page_no, png = item
        answer = await table_difficulty(png)
        await db_q.put((str(pdf_path), page_no, answer))
        in_q.task_done()


async def db_writer(db_q):
    async with aiosqlite.connect(DB) as db:
        await db.execute("""CREATE TABLE IF NOT EXISTS results
                            (pdf TEXT, page INTEGER, answer TEXT)""")
        await db.commit()
        while item := await db_q.get():
            pdf_path, page_no, answer = item
            await db.execute("INSERT INTO results VALUES (?,?,?)",
                             (pdf_path, page_no, answer))
            await db.commit()
            db_q.task_done()


# — MAIN ORCHESTRATOR —
async def main(parallel_renders=2, parallel_filters=2, parallel_ai=2):
    q_pages     = asyncio.Queue()
    q_images    = asyncio.Queue()
    q_contrasts = asyncio.Queue()

    # Enqueue all pages first
    for pdf in ROOT.glob("*.pdf"):
        doc = fitz.open(pdf)                     # cheap metadata open
        for page_no in range(len(doc)):
            await q_pages.put((pdf, page_no))
        doc.close()

    # # Launch workers (python 3.11+)
    # async with asyncio.TaskGroup() as tg:
    #     for _ in range(parallel_renders):
    #         tg.create_task(render_worker(q_pages, q_images))
    #     for _ in range(parallel_filters):
    #         tg.create_task(contrast_worker(q_images, q_contrasts))
    #     for _ in range(parallel_ai):
    #         tg.create_task(openai_worker(q_contrasts, q_pages))  # reuse q_pages placeholder
    #     tg.create_task(db_writer(q_pages))                        # final sink reuses q_pages

    ## (python 3.10)
    tasks = []

    for _ in range(parallel_renders):
        tasks.append(asyncio.create_task(render_worker(q_pages, q_images)))

    for _ in range(parallel_filters):
        tasks.append(asyncio.create_task(contrast_worker(q_images, q_contrasts)))

    for _ in range(parallel_ai):
        tasks.append(asyncio.create_task(openai_worker(q_contrasts, q_pages)))

    tasks.append(asyncio.create_task(db_writer(q_pages)))

    # Wait for first queue to drain, then signal downstream shutdown
    await q_pages.join()
    for q in (q_images, q_contrasts, q_pages):
        await q.put(None)      # poison pills for workers
    
    # Wait for all workers to finish
    await asyncio.gather(*tasks)


if __name__ == "__main__":
    asyncio.run(main())


# import sqlite3
# conn = sqlite3.connect(DB)
# c = conn.cursor()
# c.execute('''SELECT * from results''')
# rows = c.fetchall()
# df = pd.DataFrame(rows, columns = ['pdf','page','answer'])
# conn.commit()
# conn.close()