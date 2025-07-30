#!/usr/bin/env python3

import pandas as pd
import os
from glob import glob
from collections import defaultdict

folder = "/group/ctbrowngrp2/amhorst/2025-check-8000/results/sourmash_human/gather"
files = glob(os.path.join(folder, "*.csv"))

groups = defaultdict(dict)

for f in files:
    base = os.path.basename(f)
    if ".animal_plant." in base:
        prefix = base.split(".animal_plant.")[0]
        groups[prefix]["animal_plant"] = f
    elif ".gtdb.k21" in base:
        prefix = base.split(".gtdb.")[0]
        groups[prefix]["gtdb"] = f

rows = []
for basename, paths in groups.items():
    if "animal_plant" in paths and "gtdb" in paths:
        def safe_sum(path):
            try:
                df = pd.read_csv(path)
                return df["f_unique_weighted"].sum() if "f_unique_weighted" in df else 0
            except pd.errors.EmptyDataError:
                return 0

        a_sum = safe_sum(paths["animal_plant"])
        g_sum = safe_sum(paths["gtdb"])
        rows.append((basename, a_sum, g_sum))

output_df = pd.DataFrame(rows, columns=["basename", "animal_plant", "gtdb"])
output_df.to_csv("/group/ctbrowngrp2/amhorst/2025-check-8000/results/sourmash_human/250623_count_fweigthed.csv", index=False)
