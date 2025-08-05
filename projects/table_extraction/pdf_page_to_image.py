import fitz  # PyMuPDF
from PIL import Image

def pdf_page_to_image(pdf_path, page_number, output_path, zoom=2):
    """
    Converts a specific page of a PDF to an image.

    Parameters:
    - pdf_path: str - Path to the input PDF file
    - page_number: int - Page number to extract (0-based)
    - output_path: str - Path to save the image (e.g., 'output.png')
    - zoom: int or float - Zoom factor to improve resolution (default 2)
    """
    # Open the PDF file
    doc = fitz.open(pdf_path)

    # Ensure valid page number
    if page_number < 0 or page_number >= len(doc):
        raise ValueError(f"Invalid page number. PDF has {len(doc)} pages.")

    # Load the page
    page = doc.load_page(page_number)

    # Create a pixmap (rendered image) with zoom for better quality
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)

    # Save the pixmap to file
    pix.save(output_path)

    print(f"Page {page_number + 1} saved as image to '{output_path}'")

# Example usage
if __name__ == "__main__":
    pdf_file = "CARDENAS_alejandra_Transcript and CGPA.pdf"
    page_num = 0  # First page
    output_file = "page1.png"

    pdf_page_to_image(pdf_file, page_num, output_file)
