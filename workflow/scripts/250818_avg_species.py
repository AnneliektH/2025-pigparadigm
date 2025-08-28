import pandas as pd
import sys

# usage: python script.py input.tsv output.tsv

input_file = sys.argv[1]
output_file = sys.argv[2]

# read input
df = pd.read_csv(input_file, sep=",")

# filter, group, aggregate
out = (
    df[df["rank"] == "species"]
    .groupby("lineage")
    .agg(avg_fraction=("fraction", "mean"), n_found=("lineage", "size"))
    .reset_index()
)

# save
out.to_csv(output_file, sep=",", index=False)
