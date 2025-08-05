from PIL import Image
import pytesseract
import pandas as pd
import re

# Load the image
image_path = "page1.png"
image = Image.open(image_path)

# Use Tesseract to extract text from the image
text = pytesseract.image_to_string(image)

# Extract table rows using regex
rows = re.findall(r"10\d{3}\s+[\sA-Z]+\s+2010-\d\s+\d{2}\s+\d{2}\s+[A-Z]+\s+\d{2}\.\d{2}\.\d{4}", text)

# Process each row into structured data
table_data = []
for row in rows:
    parts = re.split(r"\s{2,}", row.strip())
    if len(parts) == 6:
        table_data.append(parts)

# Define column headers
columns = ["CODE", "COURSES", "ACADEMIC PERIOD", "CREDITS", "GRADES", "DATE"]

# Create DataFrame
df = pd.DataFrame(table_data, columns=columns)


# Save as CSV
csv_path = "extracted_table.csv"
df.to_csv(csv_path, index=False)

csv_path
