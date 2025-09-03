import re
import csv
import sys
import os
import argparse
from utils import load_nhc_mapping


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Convert medication data from text format to CSV."
    )
    parser.add_argument("input_file", help="Input text file containing medication data")
    parser.add_argument(
        "output_dir",
        help="Output directory for CSV file (default: same as input file directory)",
    )
    parser.add_argument(
        "--map-id",
        metavar="MAPPING_FILE",
        help="Path to NHC to study ID mapping CSV file for converting numeric IDs to HCB format",
    )
    return parser.parse_args()


def convert_id_if_needed(line, nhc_mapping):
    """Convert numeric ID to HCB format using mapping if available."""
    # If it's already HCB format, return as-is (no mapping needed)
    if re.match(r"^HCB\d{3}$", line):
        return line

    # If it's numeric and mapping is available, try to map it
    if nhc_mapping and re.match(r"^\d{4,}$", line):
        # Remove leading zeros for mapping lookup
        nhc_key = line.lstrip("0")
        mapped_id = nhc_mapping.get(nhc_key)

        if mapped_id:
            print(f"🔄 Mapped ID: {line} -> {mapped_id}")
            return mapped_id
        else:
            print(f"⚠️  [WARNING] Numeric ID '{line}' not found in mapping, using 'NA'")
            return "NA"

    # If it's numeric but no mapping provided, return as-is
    return line


args = parse_arguments()

# Validate input file
if not os.path.isfile(args.input_file):
    print(f"❌ Error: Input file '{args.input_file}' does not exist.")
    sys.exit(1)

# Load mapping if provided
nhc_mapping = None
if args.map_id:
    if not os.path.isfile(args.map_id):
        print(f"❌ Error: Mapping file '{args.map_id}' does not exist.")
        sys.exit(1)

    try:
        nhc_mapping = load_nhc_mapping(args.map_id)

    except Exception as e:
        print(f"❌ Error loading mapping file: {e}")
        sys.exit(1)

# Generate output filename and path
base = os.path.splitext(os.path.basename(args.input_file))[0]
if args.output_dir:
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir, exist_ok=True)
    output_file = os.path.join(args.output_dir, f"{base}.csv")
else:
    input_dir = os.path.dirname(args.input_file)
    output_file = os.path.join(input_dir, f"{base}.csv")


# Read input file with error handling
try:
    with open(args.input_file, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]
except Exception as e:
    print(f"❌ Error reading input file: {e}")
    sys.exit(1)

# Process medication data
output = []
current_id = None
medication_count = 0
i = 0

print("\n🔄 Processing medication data...")
while i < len(lines):
    line = lines[i]

    # Check if line is an ID (numeric 4+ digits or HCB format)
    if re.match(r"^\d{4,}$", line) or re.match(r"^HCB\d{3}$", line):
        # Convert ID if needed (mapping only applies to numeric IDs)
        current_id = convert_id_if_needed(line, nhc_mapping)
        i += 1
    else:
        # Process medication and posology
        medication = lines[i]
        if i + 1 < len(lines):
            posology = lines[i + 1]
            output.append([current_id, medication, posology])
            medication_count += 1
            i += 2
        else:
            print(
                f"⚠️  [WARNING] Medication without posology: '{medication}' (ID: {current_id})"
            )
            i += 1

print(f"✅ Processed {medication_count} medication entries")

# Write to CSV with header (always included)
print(f"\n💾 Writing results to: {output_file}")
try:
    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter=",")
        writer.writerow(["id", "medication", "posology"])
        writer.writerows(output)
    print(f"✅ Successfully wrote {len(output)} rows to CSV file")
except Exception as e:
    print(f"❌ Error writing output file: {e}")
    sys.exit(1)

print(f"\n🎉 Process completed successfully!")
print(f"📊 Summary:")
print(f"   - Input file: {args.input_file}")
print(f"   - Output file: {output_file}")
print(f"   - Total medications: {medication_count}")
print(f"   - Mapping used: {'Yes' if nhc_mapping else 'No'}")
