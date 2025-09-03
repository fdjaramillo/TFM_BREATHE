import chardet
import csv


def load_nhc_mapping(file_path):
    """Load the NHC to study ID mapping from a CSV file."""
    nhc_to_id = {}
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                nhc_to_id[row["nhc"]] = row["id"]
    except FileNotFoundError:
        print(f"❌ Error: Mapping file not found at '{file_path}'")
        exit(1)
    return nhc_to_id


def detect_encoding(file_path, sample_size=1024):
    """
    Detect the encoding of a file by analyzing its content using chardet.

    Args:
        file_path (str): Path to the file.
        sample_size (int): Number of bytes to read for detection (default: 1024).

    Returns:
        str: Detected encoding, or None if detection fails.
    """
    try:
        with open(file_path, "rb") as f:
            raw_data = f.read(sample_size)
            if not raw_data:
                raise ValueError("File is empty or unreadable")
        result = chardet.detect(raw_data)
        encoding = result.get("encoding", None)
        # Treat 'ascii' as 'latin-1' (iso-8859-1)
        if encoding == "ascii":
            encoding = "latin-1"
        # Fallback to utf-8 or latin-1 if detection fails
        if not encoding:
            print(
                f"⚠️ Encoding detection failed for {file_path}, trying utf-8 and latin-1."
            )
            for fallback in ["utf-8", "latin-1"]:
                try:
                    with open(file_path, encoding=fallback) as test_f:
                        test_f.read(100)
                    return fallback
                except Exception:
                    continue
            return None
        return encoding
    except Exception as e:
        print(f"⚠️ Error detecting encoding for {file_path}: {e}")
        return None
