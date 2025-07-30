#!/usr/bin/env python3
"""
Concatenate the sourmash gather results for different dereplication levels of MAGs. 
Script reads csvs with gatehr results, and deposits f_unique_weighted values
into a single document
Anneliek ter Horst, July 2025
"""
import os
import glob
import pandas as pd

def extract_f_unique(file):
    try:
        df = pd.read_csv(file)
        return df['f_unique_weighted'].iloc[0] if not df.empty else float('nan')
    except Exception:
        return float('nan')

def process(folder, output_csv):
    patterns = ['mag_all', 'mag99', 'mag95']
    data = {}

    for pattern in patterns:
        files = glob.glob(os.path.join(folder, f'*{pattern}.csv'))
        print(f'Pattern: {pattern}, files found: {len(files)}')

        for file in files:
            basename = os.path.basename(file).replace(f'.{pattern}.csv', '')
            value = extract_f_unique(file)

            if basename not in data:
                data[basename] = {}
            data[basename][pattern] = value

    df_out = pd.DataFrame.from_dict(data, orient='index')
    df_out = df_out.reindex(columns=patterns)  # ensure column order
    df_out.index.name = 'acc'
    df_out.to_csv(output_csv)
    
# === Edit these paths:
process(
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/gather_human',
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/250716_gathersum_drep.human.csv'
)
