#!/usr/bin/env python3
# ssl_json_to_csv.py
# Converts an SSLyze JSON scan result to an import-ready certificate CSV.
#
# Changes:
#   2025-07-10 - Initial creation: parse sslyze JSON, output Alias/Certdata/URI CSV

import argparse
import base64
import csv
import json
import sys
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert SSLyze JSON scan results to certificate import CSV."
    )
    parser.add_argument("input_json", help="Path to the SSLyze JSON results file")
    parser.add_argument(
        "-o", "--output",
        help="Output CSV file path (default: <input_stem>.csv next to the input file)",
    )
    return parser.parse_args()


# Extract the first leaf certificate PEM and the SNI hostname from a single scan result entry.
def extract_cert_row(scan_entry):
    hostname = scan_entry.get("server_location", {}).get("hostname", "")
    alias = f"cert-{hostname}"

    scan_result = scan_entry.get("scan_result")
    if scan_result is None:
        return None

    cert_info = scan_result.get("certificate_info", {})

    if not cert_info or cert_info.get("status") != "COMPLETED":
        return None

    result = cert_info.get("result", {})
    uri = result.get("hostname_used_for_server_name_indication", hostname)

    deployments = result.get("certificate_deployments", [])
    if not deployments:
        return None

    chain = deployments[0].get("received_certificate_chain", [])
    if not chain:
        return None

    pem = chain[0].get("as_pem", "")
    if not pem:
        return None

    # Encode PEM bytes as base64 (strip trailing newline to stay clean)
    certdata = base64.b64encode(pem.encode()).decode()

    return {"Alias": alias, "Certdata": certdata, "URI (optional)": uri}


def main():
    args = parse_args()
    input_path = Path(args.input_json)

    if not input_path.exists():
        print(f"Error: file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_suffix(".csv")

    with input_path.open() as fh:
        data = json.load(fh)

    rows = []
    for entry in data.get("server_scan_results", []):
        row = extract_cert_row(entry)
        if row:
            rows.append(row)
        else:
            hostname = entry.get("server_location", {}).get("hostname", "<unknown>")
            print(f"Warning: skipping {hostname} — certificate_info not completed or empty", file=sys.stderr)

    if not rows:
        print("No certificate rows produced. Check that scan_result.certificate_info.status == 'COMPLETED'.", file=sys.stderr)
        sys.exit(1)

    with output_path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["Alias", "Certdata", "URI (optional)"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Written {len(rows)} row(s) to {output_path}")


if __name__ == "__main__":
    main()
