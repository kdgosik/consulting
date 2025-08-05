import os
import sys
import re
import json
from glob import glob
from pathlib import Path
from dotenv import load_dotenv

import numpy as np
import pandas as pd
import sqlite3

from pydantic import BaseModel
from typing import Optional

from openai import OpenAI
from agents import Agent, Runner
from agents import set_tracing_export_api_key
import importlib.metadata
## loads the .env file with OPENAI_API_KEY set
load_dotenv()


## utils.py
import utils
importlib.reload(utils)
import datetime

x = datetime.datetime.now()

patterns_of_interest = ["/home/jupyter/bfrg-eleison-inbound-data/2025-03-25-initial-data/302/*.pdf"]

pdfs_of_interest = []
[pdfs_of_interest.extend(glob(pattern)) for pattern in patterns_of_interest]
pdfs_of_interest

# === INPUTS ===
# Must-have to ensure trace reporting
set_tracing_export_api_key(os.environ['OPENAI_API_KEY'])
DEFAULT_MODEL = 'gpt-4.1-2025-04-14'
PDF_PATHS = pdfs_of_interest[1]
TRIAGE_AGENT = utils.triage_agent
EXTRACT_AGENT = utils.ML_table_parser
SCHEMA_AGENT = utils.table_schema_generator
QC_AGENT = utils.QC_agent

# EXTRACT_AGENT_SCHEMA = utils.ML_table_parser_dataclass

# === PATHS ===
PROJECT = os.getcwd()
RESULTS = f'{PROJECT}/results'


# === Load triage results ===
conn = sqlite3.connect("triage_log.db")
cursor = conn.cursor()
cursor.execute("SELECT pdf_path, page_number, data FROM triage")
rows = cursor.fetchall()
df = pd.DataFrame(rows,columns=['pdf_path', 'page_number', 'data']).drop_duplicates()
jl = [json.loads(d) for d in df['data'].tolist()]

table_df = (
    df
    .assign(filter_val = lambda x: x['data'].apply(lambda x: json.loads(x)['contains_table'] if isinstance(x, str) else x))
    .query('filter_val')
)

# extracted_page = df.query('pdf_path==@PDF_PATHS & page_number==@pn')
# json.loads(extracted_page['data'][598])


# list(range(1,39))
pn = 1
pn = list(range(1,24)) # 1 - 23
# pn = list(range(24,39)) # 24 - 38
# pn = list(range(41,50)) # 41 - 49 # challenging with lots of white space
batch_data = utils.extract_pages_from_pdf(PDF_PATHS, pn)
base64_img = batch_data[pn]

# Load the PDF
input_items = [{
    "role": "user",
    "content": [{"type": "input_image", "image_url": f"data:image/png;base64,{base64_img}"}]
}]


pdf_path = PDF_PATHS
bn = os.path.basename(PDF_PATHS)
results_path = Path(f'{RESULTS}/extract_table_'+x.strftime('%Y%m%d%H%M'))
results_path.mkdir(exist_ok=True)
csv_file = results_path / f'{bn}_{pn}_extracted_table.csv'

# Call API with retry and timeout
table_parser_result = await Runner.run(EXTRACT_AGENT, input_items)
table_parser_result.final_output


md_table=utils.markdown_table_to_csv(table_parser_result.final_output, csv_path=csv_file)
utils.show_pdf_and_table_side_by_side(pdf_path, pn, csv_file, dpi=200, save=True)





## Embbed text
conn = sqlite3.connect("embedded_text.db")
cursor = conn.cursor()


cursor.execute("SELECT pdf_path, page_number, page_text, table_title, table_current_page, table_total_pages FROM embed LIMIT 23")
rows = cursor.fetchall()

embed_df = (
    pd.DataFrame(rows, columns = ['pdf_path','page_number', 'page_text','table_title', 'table_current_page', 'table_total_pages'])
    .drop_duplicates()
)

page_text = embed_df['page_text'][0]


# Call API to generate schema
schema_result = await Runner.run(SCHEMA_AGENT, page_text)
print(schema_result.final_output)

## execute the first code block found in string to create dataclass schema
inferred_schema = utils.extract_python_code_blocks(schema_result.final_output)[0]
print(inferred_schema)
## Creates a pydantic model called StudyRecord
exec(inferred_schema)



prompt = f"""
Extract the following OCR text into a JSON array that conforms to this schema:

## Inferred dataclass from above
{StudyRecord.schema_json(indent=2)}

Text:
{page_text}
"""

msg = (prompt)

input_items = [{"role": "user", "content": [
    {"type": "input_image", "image_url": f"data:image/png;base64,{base64_img}"}
]}]
input_items.append({"content": msg, "role": "user"})

table_qc_result = await Runner.run(QC_AGENT, input_items)
print(table_qc_result.final_output)        


table_schema_result = await Runner.run(EXTRACT_AGENT, input_items)
table_schema_result.final_output

jd_results = utils.extract_json_code_blocks(table_schema_result.final_output)[0]
pd.DataFrame(json.loads(jd_results))





    
bn = os.path.basename(pdf_path)
pn = 1
out=[]
for i in range(5):    
    csv_file = f'{bn}_{pn}_extracted_table_call{i}.csv'

    # Call API with retry and timeout
    table_parser_result = await Runner.run(EXTRACT_AGENT, input_items)
    table_parser_result.final_output

    prompt = f"""
    Extract the following OCR text into a JSON array that conforms to this schema:
    
    {StudyRecord.schema_json(indent=2)}
    
    Text:
    {table_parser_result.final_output}
    """
    
    input_items=[{"role": "user", "content": prompt}]
    table_schema_result = await Runner.run(EXTRACT_AGENT, input_items)
    # table_schema_result.final_outpu
    df = pd.DataFrame(json.loads(table_schema_result.final_output))
    # df = pd.read_csv(csv_file)
    out.append({'pdf_path':bn,
                'page_number':pn,
                'attempt':i,
                'markdown_string':md_table,
                'df':df})
        

        
        
        
        



# Dynamically generate schema
class_attrs = "\n".join([f"{name}: Optional[str]" for name in field_names])

pydantic_schema = f"""
from pydantic import BaseModel
from typing import Optional

class TableRow(BaseModel):
{class_attrs}
"""

print(pydantic_schema)



from pydantic import BaseModel
from typing import Optional
import re


def parse_markdown_table(md: str) -> list[list[str]]:
    """Convert markdown table string into list of lists."""
    lines = md.strip().splitlines()
    rows = [re.split(r'\s*\|\s*', line.strip().strip("|")) for line in lines if '|' in line]
    return rows


# Clean header names to valid Python identifiers
def to_snake_case(name: str) -> str:
    """Convert string to snake_case for valid Python identifier."""
    name = re.sub(r"[^\w\s]", "", name)
    name = re.sub(r"\s+", "_", name.strip())
    return name.lower()


def generate_pydantic_model_from_md_table(md: str, model_name: str = "TableRow") -> str:
    table = parse_markdown_table(md)
    headers = table[0]
    fields = [to_snake_case(h) for h in headers]

    schema_lines = "\n".join([f"    {field}: Optional[str]" for field in fields])
    pydantic_schema = f"""
from pydantic import BaseModel
from typing import Optional

class TableRow(BaseModel):
{class_attrs}
"""
    return pydantic_schema


def is_schema_consistent(old_schema: str, new_schema: str) -> bool:
    return old_schema.strip() == new_schema.strip()


l=[]
for i in range(1):
    table_parser_result = await Runner.run(EXTRACT_AGENT, input_items)
    new_schema=generate_pydantic_model_from_md_table(table_parser_result.final_output)
    
    res = is_schema_consistent(pydantic_schema, new_schema)
    l.append(res)


# ## Next Steps
#  - read first page that is a table
#  - generate schema
#  - check schema against extracted table
#  - regenerate schema
#  - check against previous schema
#  - use schema as context for next pages
#      - develop traige agent to detect when table changes
