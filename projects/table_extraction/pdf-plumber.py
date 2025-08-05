import pdfplumber
pdf_path = "CARDENAS_alejandra_Transcript and CGPA.pdf"

with pdfplumber.open(pdf_path) as pdf:
    # Extract text from the first page
    first_page = pdf.pages[0]
    text = first_page.extract_text()

print(text)