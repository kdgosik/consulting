from pypdf import PdfReader, PdfWriter

def split_pdf(input_path, output_prefix="page"):
    reader = PdfReader(input_path)
    total_pages = len(reader.pages)

    for i in range(total_pages):
        writer = PdfWriter()
        writer.add_page(reader.pages[i])
        
        output_filename = f"{output_prefix}_{i + 1}.pdf"
        with open(output_filename, "wb") as output_file:
            writer.write(output_file)

        print(f"Saved: {output_filename}")

# Example usage
input_doc_path = "CARDENAS_alejandra_Transcript and CGPA.pdf"
split_pdf(input_doc_path, output_prefix="output_page")
