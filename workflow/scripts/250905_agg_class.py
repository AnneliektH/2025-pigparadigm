import pandas as pd
import sys

# usage: python script.py input.tsv output.tsv

input_file = sys.argv[1]
output_file = sys.argv[2]


classes_singlem = [
    "c__Verrucomicrobiia",
    "c__Vampirovibrionia",
    "c__Thermoplasmata",
    "c__Spirochaetia",
    "c__Saccharimonadia",
    "c__Negativicutes",
    "c__Methanobacteria",
    "c__Kiritimatiellia",
    "c__Gammaproteobacteria",
    "c__Fusobacteriia",
    "c__Coriobacteriia",
    "c__Clostridia",
    "c__Campylobacteria",
    "c__Bacteroidia",
    "c__Bacilli",
    "c__Alphaproteobacteria",
    "c__Actinomycetes"
]

pattern = "|".join(classes_singlem)

# read input
df = pd.read_csv(input_file, sep=",")

# keep only rows where rank == "class"
df = df[df["rank"] == "class"]

df = df[df["lineage"].str.contains(pattern, na=False)]

df.to_csv(output_file, sep=",", index=False)

# # group by class (lineage/class column — adjust name if needed)
# summary = (
#     df_filtered
#     .groupby("lineage")  # <-- change to the actual column that has the class name
#     .agg(
#         avg_fraction=("fraction", "mean"),
#         count=("rank", "count")
#     )
#     .reset_index()
# )

# # save both filtered data and summary
# summary.to_csv(output_file, sep=",", index=False)


