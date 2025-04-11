import re
import csv
from pathlib import Path

def parse_crispr_directory(input_dir, output_csv):
    data = []

    for filepath in Path(input_dir).glob("*.txt"):
        with open(filepath) as f:
            lines = f.readlines()

        sequence = crispr = None
        start = stop = repeats = avg_len_repeat = avg_len_spacer = None

        for line in lines:
            seq_match = re.match(r"Sequence '(.+?)'", line)
            if seq_match:
                sequence = seq_match.group(1)

            crispr_match = re.match(r"(CRISPR \d+)\s+Range: (\d+) - (\d+)", line)
            if crispr_match:
                crispr = crispr_match.group(1)
                start = crispr_match.group(2)
                stop = crispr_match.group(3)

            summary_match = re.match(r"Repeats:\s+(\d+)\s+Average Length:\s+(\d+)\s+Average Length:\s+(\d+)", line)
            if summary_match:
                repeats = summary_match.group(1)
                avg_len_repeat = summary_match.group(2)
                avg_len_spacer = summary_match.group(3)
                data.append([sequence, crispr, start, stop, repeats, avg_len_repeat, avg_len_spacer])

    with open(output_csv, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['sequence', 'crispr', 'start', 'stop', 'repeats', 'avg_len_repeat', 'avg_len_spacer'])
        writer.writerows(data)

# Example usage
parse_crispr_directory("/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/crispr/minced", "../../results/crispr/250410_minced_result_parsed.csv")
