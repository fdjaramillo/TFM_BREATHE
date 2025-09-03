#!/usr/bin/env python3
import os
import csv
import traceback
import argparse
import fitz  # PyMuPDF
from datetime import datetime
from utils import load_nhc_mapping


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Extract data from blood analysis PDFs and save to structured CSV files."
    )
    parser.add_argument("input_dir", help="Directory containing the source PDF files.")
    parser.add_argument(
        "output_dir", help="Directory where the output CSV files will be saved."
    )
    parser.add_argument(
        "mapping_file", help="Path to the NHC to study ID mapping CSV file."
    )
    return parser.parse_args()


def extract_header_info(pdf_path):
    doc = fitz.open(pdf_path)
    page = doc[0]
    blocks = page.get_text("blocks", sort=True)[1:3]

    header_info = {
        "nhc": "NA",
        "name": "NA",
        "sample_reception_date": "NA",
        "birth_date": "NA",
    }

    # Block 1: name and NHC
    lines1 = blocks[0][4].splitlines()
    # header_info["name"] = lines1[0].strip()
    header_info["nhc"] = (
        lines1[1].strip().replace("NHC: ", "") if "NHC:" in lines1[1] else "NA"
    )

    # Block 2: dates
    for line in blocks[1][4].splitlines():
        if "Data recepció mostra" in line:
            date = line.split(",")[0].replace(" Data recepció mostra: ", "").strip()
            header_info["sample_reception_date"] = datetime.strptime(
                date, "%d/%m/%Y"
            ).strftime("%Y-%m-%d")
        elif "Data naix." in line:
            date = line.split(":")[1].strip()
            header_info["birth_date"] = datetime.strptime(date, "%d/%m/%Y").strftime(
                "%Y-%m-%d"
            )

    doc.close()
    return header_info


def write_csv(file_path, fieldnames, data_rows):
    """Write data to a CSV file."""
    with open(file_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data_rows)


def extract_haemogram_values(pdf_path):
    doc = fitz.open(pdf_path)

    haemogram_results = []
    manual_results = []
    automatic_results = []

    # Add vertical line to help split columns
    vertical_line = ((377, 282), (377, 758))
    current_section = None

    for page in doc:
        for table in page.find_tables(add_lines=[vertical_line]).tables:
            for row in table.extract():
                if not row or len(row) < 3:
                    continue

                parameter, value, unit = row[0].strip(), row[1].strip(), row[2].strip()

                # Detect new sections based on uppercase text
                if parameter.isupper():
                    if parameter in [
                        "AL·LÈRGENS ESPECÍFICS",
                        "HEMOSTÀSIA GENERAL",
                        "IMMUNOQUÍMICA",
                    ]:
                        doc.close()
                        return haemogram_results, (
                            manual_results if manual_results else automatic_results
                        )
                    current_section = parameter
                    continue

                # Skip lines containing 'Prestació,Resultat,Unitat'
                if (
                    parameter == "Prestació"
                    and value == "Resultat"
                    and unit == "Unitat"
                ):
                    continue

                # Skip invalid rows
                if not parameter or not value or not unit:
                    continue

                # Store data in the appropriate section
                entry = {"parameter": parameter, "value": value, "unit": unit}
                if current_section == "HEMOGRAMA":
                    haemogram_results.append(entry)
                elif current_section == "REVISIÓ LEUCOCITÀRIA MANUAL":
                    manual_results.append(entry)
                elif current_section == "RECOMPTE DIFERENCIAL AUTOMÀTIC":
                    automatic_results.append(entry)

    doc.close()
    return haemogram_results, manual_results if manual_results else automatic_results


def extract_ige_values(pdf_path):
    doc = fitz.open(pdf_path)
    ige_total = "NA"
    specifics, recombinants = {}, []
    current_section, current_subgroup = None, None
    vertical_line = ((377, 282), (377, 758))
    for page in doc:
        styled_blocks = page.get_text("dict", flags=fitz.TEXTFLAGS_TEXT)["blocks"]
        for table in page.find_tables(add_lines=[vertical_line]):
            for row in table.extract():
                allergen, value, unit = row[0].strip(), row[1].strip(), row[2].strip()
                ref_interval = row[3].strip() if len(row) > 3 else "NA"

                if allergen == "AL·LÈRGENS ESPECÍFICS":
                    current_section = "AL·LÈRGENS ESPECÍFICS"
                    continue
                elif allergen == "AL·LÈRGENS RECOMBINANTS":
                    current_section = "AL·LÈRGENS RECOMBINANTS"
                    continue
                if current_section == "AL·LÈRGENS ESPECÍFICS" and allergen.startswith(
                    "AL·LÈRGIA"
                ):
                    current_subgroup = allergen.replace("AL·LÈRGIA ", "")
                    continue

                # Save IgE Total
                if "IGE total" in allergen:
                    ige_total = value
                    continue

                # Skip if does not contains IgE
                if "IgE" not in allergen:
                    continue

                # Skip if there's no unit (to filter non-result lines)
                if not unit:
                    continue

                # Check bold
                bold = any(
                    value in span.get("text", "") and "Bold" in span.get("font", "")
                    for block in styled_blocks
                    for line in block.get("lines", [])
                    for span in line.get("spans", [])
                )

                # Skip if not bold
                if not bold:
                    continue

                entry = {
                    "allergen": allergen,
                    "value": value,
                    "unit": unit,
                    "ref_interval": ref_interval,
                }
                if current_section == "AL·LÈRGENS ESPECÍFICS" and current_subgroup:
                    specifics.setdefault(current_subgroup, []).append(entry)
                elif current_section == "AL·LÈRGENS RECOMBINANTS":
                    recombinants.append(entry)
    doc.close()
    return ige_total, specifics, recombinants


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
    # Create main output directory and subdirectories
    hematology_dir = os.path.join(args.output_dir, "hematology")
    immunology_dir = os.path.join(args.output_dir, "immunology")

    try:
        os.makedirs(args.output_dir, exist_ok=True)
        os.makedirs(hematology_dir, exist_ok=True)
        os.makedirs(immunology_dir, exist_ok=True)
    except PermissionError:
        print(
            f"❌ Error: Cannot write to output directory '{args.output_dir}'. Check permissions."
        )
        return
    except Exception as e:
        print(f"❌ Error: Failed to create output directories: {e}")
        return

    # Define output file paths
    csv_metadata = os.path.join(args.output_dir, "metadata_auto.csv")
    csv_haemogram = os.path.join(hematology_dir, "hemograma_auto.csv")
    csv_leucocytes = os.path.join(hematology_dir, "leucocitos_auto.csv")
    csv_ige_total = os.path.join(immunology_dir, "ige_total_auto.csv")
    csv_ige_specific = os.path.join(immunology_dir, "ige_specific_auto.csv")
    csv_ige_recombinant = os.path.join(immunology_dir, "ige_recombinant_auto.csv")

    # --- Load Mapping ---
    nhc_to_id = load_nhc_mapping(args.mapping_file)

    # --- Initialize Data Lists ---
    header_rows, haemogram_rows, leucocyte_rows = [], [], []
    ige_total_rows, ige_specific_rows, ige_recombinant_rows = [], [], []
    errors = []

    # --- Process each PDF file ---
    print(f"📁 Processing PDFs from: {args.input_dir}")
    for filename in os.listdir(args.input_dir):
        if not filename.lower().endswith(".pdf"):
            continue

        pdf_path = os.path.join(args.input_dir, filename)
        print(f"📄 Processing {filename}...")

        try:
            header = extract_header_info(pdf_path)
            haemogram_results, leucocyte_results = extract_haemogram_values(pdf_path)
            ige_total, ige_specifics, ige_recombinants = extract_ige_values(pdf_path)

            nhc = header.get("nhc", "NA").lstrip("0")
            study_id = nhc_to_id.get(nhc, f"UNKNOWN_NHC_{nhc}")

            # Append data to lists
            header["id"] = study_id
            header_rows.append(header)

            for entry in haemogram_results:
                entry["id"] = study_id
                haemogram_rows.append(entry)

            for entry in leucocyte_results:
                entry["id"] = study_id
                leucocyte_rows.append(entry)

            if ige_total != "NA":
                ige_total_rows.append({"id": study_id, "value": ige_total})

            for subgroup, items in ige_specifics.items():
                for entry in items:
                    entry["id"] = study_id
                    entry["subgroup"] = subgroup
                    ige_specific_rows.append(entry)

            for entry in ige_recombinants:
                entry["id"] = study_id
                ige_recombinant_rows.append(entry)

        except Exception as e:
            error_msg = f"Failed to process {filename}: {e}"
            print(f"❌ [ERROR] {error_msg}")
            traceback.print_exc()
            errors.append(error_msg)
            continue

    # --- Write all data to CSV files ---
    write_csv(
        csv_metadata, ["id", "name", "sample_reception_date", "birth_date"], header_rows
    )
    write_csv(csv_haemogram, ["id", "parameter", "value", "unit"], haemogram_rows)
    write_csv(csv_leucocytes, ["id", "parameter", "value", "unit"], leucocyte_rows)
    write_csv(csv_ige_total, ["id", "value"], ige_total_rows)
    write_csv(
        csv_ige_specific,
        ["id", "subgroup", "allergen", "value", "unit", "ref_interval"],
        ige_specific_rows,
    )
    write_csv(
        csv_ige_recombinant,
        ["id", "allergen", "value", "unit", "ref_interval"],
        ige_recombinant_rows,
    )

    print("\n[OK] Extraction completed.")
    print(f"✅ Results saved in: {args.output_dir}")
    if errors:
        print("\n[SUMMARY] Errors occurred during processing:")
        for err in errors:
            print(f" - {err}")


if __name__ == "__main__":
    main()
