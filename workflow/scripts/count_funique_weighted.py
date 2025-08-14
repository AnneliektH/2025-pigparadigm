import pandas as pd
import glob
import os

# Path to folder with your files
folder = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/gtdb_pangenomedb/gather_k31"

# Find all CSV files
files = glob.glob(os.path.join(folder, "*.csv"))

# Dictionary to collect results
results = {}

for file in files:
    filename = os.path.basename(file)
    
    # Split into basename and suffix
    parts = filename.split(".", 1)
    if len(parts) != 2:
        continue  # skip files that don't match pattern
    basename, suffix = parts

    # Read file and compute sum of f_unique_weighted, or 0 if empty
    try:
        df = pd.read_csv(file)
        if "f_unique_weighted" in df.columns:
            value = df["f_unique_weighted"].sum()
        else:
            value = 0
    except pd.errors.EmptyDataError:
        value = 0

    # Store in dictionary
    if basename not in results:
        results[basename] = {}
    results[basename][suffix] = value

# Convert to DataFrame
df_result = pd.DataFrame.from_dict(results, orient="index")
df_result.index.name = "basename"
df_result = df_result.fillna(0)

# Save to CSV
df_result.to_csv("/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/gtdb_pangenomedb/250811_gather.human_gtdbMAG.k31.csv")
