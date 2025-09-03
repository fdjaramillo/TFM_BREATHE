import os
import fitz  # PyMuPDF

# Directory with the PDFs
input_dir = r"C:/Users/fdjaramillo/Downloads/analitica-all-files"

# Initialize list to store files with "REVISIÓ LEUCOCITÀRIA MANUAL"
files_with_revisio_manual = []

# Process each PDF file
for filename in os.listdir(input_dir):
    if not filename.lower().endswith(".pdf"):
        continue

    pdf_path = os.path.join(input_dir, filename)

    try:
        # Open the PDF
        doc = fitz.open(pdf_path)

        # Check each page for the target value
        for page in doc:
            for table in page.find_tables():
                for row in table.extract():
                    if not row or len(row) < 1:
                        continue

                    # Check if the first column contains "REVISIÓ LEUCOCITÀRIA MANUAL"
                    if row[0].strip() == "REVISIÓ LEUCOCITÀRIA MANUAL":
                        files_with_revisio_manual.append(filename)
                        raise StopIteration  # Stop further processing of this file

    except StopIteration:
        pass  # Continue to the next file
    except Exception as e:
        print(f"[ERROR] Failed to process {filename}: {e}")
        continue

# Print summary
if files_with_revisio_manual:
    print("Files containing 'REVISIÓ LEUCOCITÀRIA MANUAL':")
    for fname in files_with_revisio_manual:
        print(f" - {fname}")
else:
    print("No files contain 'REVISIÓ LEUCOCITÀRIA MANUAL'.")
