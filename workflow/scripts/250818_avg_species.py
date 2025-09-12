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
    .assign(weighted_expr=df["f_weighted_at_rank"] * df["total_weighted_hashes"] * 10000)
    .groupby("lineage")
    .agg(avg_fraction=("weighted_expr", "mean"), n_found=("lineage", "size"))
    .reset_index()
)

# save
out.to_csv(output_file, sep=",", index=False)
