import pandas as pd
from glob import glob

# --- Process .gtdb.csv files ---
gtdb_files = glob("../results/sourmash_pangenome/gather/*.gtdb.csv")
df_gtdb = pd.concat(
    (pd.read_csv(f, usecols=["name", "f_unique_weighted"]) for f in gtdb_files),
    ignore_index=True
)
sum_gtdb = df_gtdb.groupby("name")["f_unique_weighted"].sum().rename("sum_gtdb")
avg_gtdb = df_gtdb.groupby("name")["f_unique_weighted"].mean().rename("avg_gtdb")

# Write intermediate file
gtdb_out = pd.concat([sum_gtdb, avg_gtdb], axis=1)
gtdb_out.to_csv("../results/sourmash_pangenome/tmp_gtdb.csv")

# --- Process .mags_and_gtdb.csv files ---
mags_files = glob("../results/sourmash_pangenome/gather/*.mags_and_gtdb.csv")
df_mags = pd.concat(
    (pd.read_csv(f, usecols=["name", "f_unique_weighted"]) for f in mags_files),
    ignore_index=True
)
sum_mags = df_mags.groupby("name")["f_unique_weighted"].sum().rename("sum_gtdb_mags")
avg_mags = df_mags.groupby("name")["f_unique_weighted"].mean().rename("avg_gtdb_mags")

# Write intermediate file
mags_out = pd.concat([sum_mags, avg_mags], axis=1)
mags_out.to_csv("../results/sourmash_pangenome/tmp_mags.csv")

# --- Merge intermediate files ---
gtdb_df = pd.read_csv("../results/sourmash_pangenome/tmp_gtdb.csv")
mags_df = pd.read_csv("../results/sourmash_pangenome/tmp_mags.csv")

merged = pd.merge(gtdb_df, mags_df, on="name", how="outer").fillna(0)

# Save final result
merged.to_csv("../results/sourmash_pangenome/250813_species_sum_avg_funique.csv", index=False)
