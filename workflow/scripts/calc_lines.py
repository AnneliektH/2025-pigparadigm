import os
import glob

folder = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/gather"

# Patterns to match
patterns = ["*.gtdb_reps.csv", "*.gtdb_all.csv"]

# Store line counts
line_counts = []

for pattern in patterns:
    for filepath in glob.glob(os.path.join(folder, pattern)):
        with open(filepath, 'r') as f:
            num_lines = sum(1 for _ in f)
        line_counts.append((os.path.basename(filepath), num_lines))

# Convert to DataFrame
import pandas as pd
df_counts = pd.DataFrame(line_counts, columns=["filename", "num_lines"])
print(df_counts)

df_counts.to_csv("/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/line_counts_gtdb_files.csv", index=False)
