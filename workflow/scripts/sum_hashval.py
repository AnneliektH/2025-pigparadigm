import pandas as pd
import glob
import os
import sys

# get input and output from command-line arguments
folder = sys.argv[1]       # e.g., "Escherichia_coli.counts"
output_file = sys.argv[2]  # e.g., "Escherichia_coli.hashval_counts.csv"

files = glob.glob(os.path.join(folder, "*.csv"))

dfs = []
for f in files:
    df = pd.read_csv(f)
    df.columns = ["hashval", "value"]
    df = df[df["value"] == 1]  # keep only 1s
    # print(len(df))
    dfs.append(df)

combined = pd.concat(dfs, ignore_index=True)

# count number of 1s per hashval
result = combined.groupby("hashval").size().reset_index(name="num_metag")

result.to_csv(output_file, index=False)
