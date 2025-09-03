#!/usr/bin/env python3
import os
import csv
import sys
import argparse
from utils import detect_encoding


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Process CSV files for each form")
    parser.add_argument(
        "input_folder", help="Input folder containing CSV files to process"
    )
    parser.add_argument(
        "--skip-question",
        nargs="+",
        default=["IDSub", "IDVer"],
        help="Patterns to skip in question column (default: IDSub IDVer)",
    )
    parser.add_argument(
        "--skip-status",
        nargs="+",
        default=[],
        help="Patterns to skip in status column (default: IDSub IDVer)",
    )
    return parser.parse_args()


def validate_input_dir(input_dir):
    """Validate that the input directory exists and is a directory."""
    if not os.path.exists(input_dir):
        print(f"❌ Error: Input directory '{input_dir}' does not exist.")
        sys.exit(1)
    if not os.path.isdir(input_dir):
        print(f"❌ Error: '{input_dir}' is not a directory.")
        sys.exit(1)


def get_output_dir(input_dir):
    """Return output directory path named 'processed'."""
    parent_dir = os.path.dirname(os.path.abspath(input_dir))
    output_dir = os.path.join(parent_dir, "processed")
    os.makedirs(output_dir, exist_ok=True)
    return output_dir


def should_skip_row(question, status, skip_patterns_question, skip_patterns_status):
    """Return True if the row should be skipped based on question/status patterns."""
    if "2025" in question:
        return True
    if any(pattern in question for pattern in skip_patterns_question):
        return True
    if any(pattern in status for pattern in skip_patterns_status):
        return True
    return False


def process_file(input_path, skip_patterns_question, skip_patterns_status):
    """Process a single CSV file and return (form, processed_rows, error_message)."""
    try:
        encoding = detect_encoding(input_path)
        if not encoding:
            return None, None, "Encoding not detected"
        processed_rows = []
        subject_id = None
        form = None
        with open(input_path, encoding=encoding, newline="") as infile:
            reader = csv.reader(infile, delimiter=",")
            for i, row in enumerate(reader):
                if i < 2:
                    continue
                question = row[0].strip()
                value = row[1].strip()
                status = row[2].strip()
                if should_skip_row(
                    question, status, skip_patterns_question, skip_patterns_status
                ):
                    continue
                if question.startswith("Site:"):
                    subject_id = question.split("/")[1].split(":")[1].strip()
                    form = question.split("/")[3].split(":")[1].strip()
                    continue
                if subject_id and form:
                    processed_rows.append([subject_id, question, value, status])
        if not form:
            return None, None, "No form detected"
        return form, processed_rows, None
    except Exception as e:
        return None, None, str(e)


def write_output(output_path, processed_rows):
    """Write processed rows to output CSV file."""
    header = ["id", "question", "value", "status"]
    with open(output_path, "w", encoding="utf-8", newline="") as outfile:
        writer = csv.writer(outfile)
        writer.writerow(header)
        writer.writerows(processed_rows)


def main():
    args = parse_arguments()
    input_dir = args.input_folder

    validate_input_dir(input_dir)
    output_dir = get_output_dir(input_dir)

    print(f"📁 Input directory: {input_dir}")
    print(f"📁 Output directory: {output_dir}")
    print(f"🔍 Skip patterns (question): {args.skip_question}")
    print(f"🔍 Skip patterns (status): {args.skip_status}")

    processed_count = 0
    skipped_count = 0
    errors = []

    for filename in os.listdir(input_dir):
        if not filename.startswith("SubjectData") or not filename.endswith(".csv"):
            continue

        input_path = os.path.join(input_dir, filename)
        print(f"\n📄 Processing file: {input_path}")

        form, processed_rows, error = process_file(
            input_path, args.skip_question, args.skip_status
        )

        if error:
            print(f"  ❌ Error processing {filename}: {error}")
            errors.append(f"{filename}: {error}")
            skipped_count += 1
            continue

        if not processed_rows:
            print("  ⚠️  No data rows found after processing. Skipping file.")
            skipped_count += 1
            continue

        # Normalize form name: lowercase and replace spaces with underscores
        normalized_form = form.lower().replace(" ", "_")
        print(f"  ✅ Detected form: {form} (normalized: {normalized_form})")

        output_path = os.path.join(output_dir, f"{normalized_form}.csv")

        if os.path.exists(output_path):
            print("  ⚠️  Output file already exists. Skipping to avoid overwrite.")
            skipped_count += 1
            continue

        write_output(output_path, processed_rows)
        processed_count += 1

    print("\n------------------ Summary ------------------")
    print(f"✅ Files processed: {processed_count}")
    print(f"✅ Files saved to: {output_dir}")
    print(f"⚠️  Files skipped: {skipped_count}")

    if errors:
        print(f"❌ Errors ({len(errors)}):")
        for err in errors:
            print("  -", err)


if __name__ == "__main__":
    main()
