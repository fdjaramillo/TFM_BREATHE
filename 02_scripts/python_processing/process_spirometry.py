#!/usr/bin/env python3
import os
import glob
import argparse
import traceback
import re
import pandas as pd
import fitz  # PyMuPDF
from utils import load_nhc_mapping


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Extract data from spirometry PDFs and save to structured CSV files."
    )
    parser.add_argument("input_dir", help="Directory containing the source PDF files.")
    parser.add_argument(
        "output_dir", help="Directory where the output CSV files will be saved."
    )
    parser.add_argument(
        "mapping_file", help="Path to the NHC to study ID mapping CSV file."
    )
    return parser.parse_args()


def extract_patient_info(text):
    """
    Extracts only the NHC and the exploration date from the PDF text.
    """
    patient_info = {}
    lines = text.splitlines()

    for line in lines:
        line = line.strip()
        if "NHC :" in line and "Edat" in line:
            parts = line.split("Edat")
            patient_info["nhc"] = parts[0].split(":")[-1].strip()
        # Robust extraction for exploration date
        match = re.search(
            r"Data exploraci[oó]\s*:?\s*([0-9]{2}/[0-9]{2}/[0-9]{4})", line
        )
        if match:
            patient_info["date"] = match.group(1)

    return patient_info


def normalize_headers(line):
    """
    Normalizes the headers detected in a line.
    """
    # Split the line into tokens using spaces as delimiters
    tokens = re.split(r"\s{1,}", line.strip())

    # Rebuild headers based on known patterns
    known_patterns = ["%Teòric", "PostBD", "Z-Score", "%Canvi"]
    headers = []
    i = 0
    while i < len(tokens):
        token = tokens[i]
        # Check if the current token or the next one form a known pattern
        if i + 1 < len(tokens) and f"{token}{tokens[i + 1]}" in known_patterns:
            headers.append(f"{token}{tokens[i + 1]}")
            i += 2  # Skip to the next token after the pattern
        else:
            headers.append(token)
            i += 1
    return headers


def associate_repeated_headers(headers):
    """
    Associates repeated headers like "%Teòric" and "Z-Score" with the Pre and Post/PostBD contexts.
    If a header appears twice, one is assigned to Pre and the other to Post or PostBD as appropriate.
    """
    # List of headers that are repeated and should be associated with Pre and Post/PostBD
    repeated_headers = ["%Teòric", "Z-Score"]

    # Dictionary to count the occurrences of each header
    header_counts = {header: 0 for header in repeated_headers}

    # List to store headers associated with their context
    associated_headers = []

    # Detect if the context is "Post" or "PostBD"
    post_context = "PostBD" if "PostBD" in headers else "Post"

    for header in headers:
        if header in repeated_headers:
            # Increment the header counter
            header_counts[header] += 1
            # Associate with Pre or Post/PostBD according to the occurrence
            if header_counts[header] == 1:
                associated_headers.append(f"Pre.{header}")
            elif header_counts[header] == 2:
                associated_headers.append(f"{post_context}.{header}")
            else:
                # If there are more than two occurrences, keep the original header
                associated_headers.append(header)
        else:
            # Headers that are not repeated are added as is
            associated_headers.append(header)

    return associated_headers


def extract_spirometry_data(file_path):
    """
    Extracts the values from the 'ESPIROMETRIA FORÇADA' section of a PDF file.
    Handles different dynamic column formats.
    """
    print(f"\nProcessing file: {file_path}")  # Debug: file in process

    # Open the PDF file
    try:
        doc = fitz.open(file_path)
        text = doc[0].get_text("text", sort=True)
        doc.close()
    except Exception as e:
        print(f"✗ Error opening or reading the PDF file: {file_path} - {str(e)}")
        return []

    # Extract patient information
    try:
        patient_info = extract_patient_info(text)
    except Exception as e:
        print(f"✗ Error extracting patient information: {str(e)}")
        return []

    # Split the text into lines and trim spaces
    lines = text.splitlines()
    lines = [line.strip() for line in lines if line.strip()]

    # Search for the "ESPIROMETRIA FORÇADA" section
    spirometry_data = []
    spirometry_section = False
    headers = None

    for line in lines:
        if "ESPIROMETRIA FORÇADA" in line:
            spirometry_section = True
            continue

        if spirometry_section:
            # Detect end of section
            if any(
                keyword in line
                for keyword in ["HISTÒRIC", "VOLUMS PULMONARS", "DIFUSIÓ"]
            ):
                break

            # Detect header line
            if re.search(r"Pre\s+Teòric|Pre\s+Teòric\s+LIN", line, re.IGNORECASE):
                headers = normalize_headers(line)
                headers = associate_repeated_headers(headers)
                # print(f"Headers found: {headers}")  # Debug
                continue

            # Process data lines
            if any(
                param in line for param in ["FVC", "FEV1", "FEV1/FVC", "MEF", "PEF"]
            ):
                try:
                    param_match = re.match(
                        r"^\s*([A-Z]+[A-Z0-9/]*(?:\([^)]+\))?)", line
                    )
                    if param_match:
                        param_name = param_match.group(1)
                        values_part = line[param_match.end() :].strip()
                        # if param_name.startswith("FEV1/FVC"):
                        #     print(f"Processing values: {values_part}")
                        values = re.split(r"\s{2,}", values_part)
                        values = [v.strip() for v in values if v.strip()]
                        # if param_name.startswith("FEV1/FVC"):
                        #     print(f"Values found for {param_name}: {values}")

                        data_row = dict(patient_info)
                        data_row["parametro"] = param_name

                        if headers:
                            # Filter relevant headers for FEV1/FVC(%)
                            if param_name.startswith("FEV1/FVC"):
                                relevant_headers = ["Pre", "Teòric", "LIN", "PostBD"]
                            else:
                                relevant_headers = headers

                            for i, value in enumerate(values):
                                if i < len(relevant_headers) and value != "----":
                                    data_row[relevant_headers[i]] = value
                            spirometry_data.append(data_row)
                        else:
                            print(f"✗ No headers found in {file_path}. Line: {line}")
                            continue
                except Exception as e:
                    print(
                        f"✗ Error processing line: {line} - {str(e)}"
                    )  # Debug: line error

    return spirometry_data


def transform_spirometry_data(spirometry_data):
    """
    Transforms the spirometry data into a detailed tabular structure.
    """
    transformed_data = []

    for entry in spirometry_data:
        nhc = entry.get("nhc")
        fecha = entry.get("date")
        param = entry.get("parametro")
        theorical = entry.get("Teòric")
        lin = entry.get("LIN")

        # Process values for each phase (Pre, Post, etc.)
        for header in entry.keys():
            if header.startswith("Pre."):
                phase = "Pre"
                value_type = header.split(".", 1)[
                    1
                ]  # Extract the value type (e.g., "%Teòric")
                transformed_data.append(
                    {
                        "nhc": nhc,
                        "date": fecha,
                        "parameter": param,
                        "phase": phase,
                        "value_type": value_type,
                        "value": entry[header],
                    }
                )
            elif header.startswith("Post.") or header.startswith("PostBD."):
                phase = "PostBD"  # header.split(".", 1)[0]  # Assign phase PostBD
                value_type = header.split(".", 1)[1]
                transformed_data.append(
                    {
                        "nhc": nhc,
                        "date": fecha,
                        "parameter": param,
                        "phase": phase,
                        "value_type": value_type,
                        "value": entry[header],
                    }
                )
            elif header == "Pre":
                transformed_data.append(
                    {
                        "nhc": nhc,
                        "date": fecha,
                        "parameter": param,
                        "phase": "Pre",
                        "value_type": "raw",
                        "value": entry[header],
                    }
                )
            elif header == "Post" or header == "PostBD":
                transformed_data.append(
                    {
                        "nhc": nhc,
                        "date": fecha,
                        "parameter": param,
                        "phase": "PostBD",
                        "value_type": "raw",
                        "value": entry[header],
                    }
                )

        # Add general values (without specific phase)
        if theorical:
            transformed_data.append(
                {
                    "nhc": nhc,
                    "date": fecha,
                    "parameter": param,
                    "phase": "Not applicable",
                    "value_type": "theorical",
                    "value": theorical,
                }
            )
        if lin:
            transformed_data.append(
                {
                    "nhc": nhc,
                    "date": fecha,
                    "parameter": param,
                    "phase": "Not applicable",
                    "value_type": "lin",
                    "value": lin,
                }
            )
        if "%Canvi" in entry:
            transformed_data.append(
                {
                    "nhc": nhc,
                    "date": fecha,
                    "parameter": param,
                    "phase": "Not applicable",
                    "value_type": "%change",
                    "value": entry["%Canvi"],
                }
            )

    # Convert to DataFrame for easier handling
    df = pd.DataFrame(transformed_data)
    return df


def main():
    """Main function to orchestrate the PDF processing."""
    args = parse_arguments()

    # --- Validate Input Arguments ---
    if not os.path.isdir(args.input_dir):
        print(f"❌ Error: Input directory '{args.input_dir}' does not exist.")
        return
    if not os.path.isfile(args.mapping_file):
        print(f"❌ Error: Mapping file '{args.mapping_file}' does not exist.")
        return

    # --- Setup Directories and Paths ---
    # Create output directory if it doesn't exist
    try:
        os.makedirs(args.output_dir, exist_ok=True)
    except PermissionError:
        print(
            f"❌ Error: Cannot write to output directory '{args.output_dir}'. Check permissions."
        )
        return
    except Exception as e:
        print(f"❌ Error: Failed to create output directory: {e}")
        return

    output_csv = os.path.join(args.output_dir, "spirometry_auto.csv")

    # --- Load Mapping ---
    nhc_to_id = load_nhc_mapping(args.mapping_file)

    all_data = []
    errors = []

    # --- Process each PDF file ---
    print(f"📁 Processing PDFs from: {args.input_dir}")

    # Search for all PDF files in the directory
    pdf_files = glob.glob(os.path.join(args.input_dir, "*.pdf"))

    if not pdf_files:
        print(f"❌ No PDF files found in {args.input_dir}")
        return

    for pdf_file in pdf_files:
        filename = os.path.basename(pdf_file)
        print(f"📄 Processing {filename}...")

        try:
            spirometry_data = extract_spirometry_data(pdf_file)

            # Add study ID mapping to each record
            for record in spirometry_data:
                nhc = record.get("nhc", "NA").lstrip("0")
                study_id = nhc_to_id.get(nhc, f"UNKNOWN_NHC_{nhc}")
                record["id"] = study_id

            all_data.extend(spirometry_data)
        except Exception as e:
            error_msg = f"Failed to process {filename}: {e}"
            print(f"❌ [ERROR] {error_msg}")
            traceback.print_exc()
            errors.append(error_msg)
            continue

    if all_data:
        df = transform_spirometry_data(all_data)
        df.to_csv(output_csv, index=False)
        print(f"\n✅ Data saved to {output_csv}")
        print(f"✅ Results saved in: {args.output_dir}")
    else:
        print("\n❌ No spirometry data found in the PDF files.")

    if errors:
        print("\n[SUMMARY] Errors occurred during processing:")
        for err in errors:
            print(f" - {err}")


if __name__ == "__main__":
    main()
