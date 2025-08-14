import pandas as pd

def process_file(infile, sum_col_name, avg_col_name, count_col_name, replace_dict=None):
    # Read entire file
    df = pd.read_csv(infile, usecols=["lineage", "fraction", "rank", "query_name"])
    
    # Replace strings if needed
    if replace_dict:
        for old, new in replace_dict.items():
            df["lineage"] = df["lineage"].str.replace(old, new, regex=False)
    
    # Group by lineage and rank
    grouped = df.groupby(["lineage", "rank"]).agg(
        **{
            sum_col_name: ("fraction", "sum"),
            avg_col_name: ("fraction", "mean"),
            count_col_name: ("query_name", "nunique")  # unique query_name count
        }
    ).reset_index()
    
    return grouped

# --- Process both files ---
df1 = process_file("../results/sourmash_pangenome/tax/gtdb_pig.tax.summarized.csv",
                   sum_col_name="sum_gtdb", avg_col_name="avg_gtdb", count_col_name="count_gtdb")

df2 = process_file("../results/sourmash_pangenome/tax/gtdbmags_pig.tax.summarized.csv",
                   sum_col_name="sum_gtdbmag", avg_col_name="avg_gtdbmag", count_col_name="count_gtdbmag",
                   replace_dict={"Bacillota_A": "Bacillota"})

# --- Merge ---
merged = pd.merge(df1, df2, on=["lineage", "rank"], how="outer").fillna(0)

# --- Save ---
merged.to_csv("../results/sourmash_pangenome/tax/250813_merged_taxfraction.csv", index=False)
