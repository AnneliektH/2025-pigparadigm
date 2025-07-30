from pathlib import Path
from collections import defaultdict

input_folder = Path("/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/genomad/viral")  # <-- update this
output_folder = input_folder / "matched_headers"
output_folder.mkdir(exist_ok=True)

# Temporary storage for seen files
seen = defaultdict(dict)

def try_write(prefix):
    if "viral_score" in seen[prefix] and "viral_rename" in seen[prefix]:
        score_headers = seen[prefix]["viral_score"]
        rename_headers = seen[prefix]["viral_rename"]
        max_len = max(len(score_headers), len(rename_headers))
        with open(output_folder / f"{prefix}_matched.tsv", "w") as out:
            out.write("viral_score\tviral_rename\n")
            for i in range(max_len):
                score = score_headers[i] if i < len(score_headers) else ""
                rename = rename_headers[i] if i < len(rename_headers) else ""
                out.write(f"{score}\t{rename}\n")
        # Once written, remove from memory
        del seen[prefix]

for f in Path(input_folder).glob("*.fa"):
    name_parts = f.name.split("_")
    prefix = name_parts[0]
    suffix = f.name.split("_", 1)[1].rsplit(".", 1)[0]  # e.g. viral_score or viral_rename
    headers = [line[1:].strip() for line in f.read_text().splitlines() if line.startswith(">")]
    seen[prefix][suffix] = headers
    try_write(prefix)
