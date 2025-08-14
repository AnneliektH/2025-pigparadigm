import os
import pandas as pd

def extract_f_unique_sum(file):
    try:
        df = pd.read_csv(file)
        return df['f_unique_weighted'].sum() if 'f_unique_weighted' in df.columns else float('nan')
    except Exception:
        return float('nan')

def process_sum(folder, output_csv):
    data = {}

    for file in os.listdir(folder):
        if file.endswith('.mags_and_gtdb.csv'):
            basename = file.replace('.mags_and_gtdb.csv', '')
            full_path = os.path.join(folder, file)
            value = extract_f_unique_sum(full_path)
            data.setdefault(basename, {})['mags_and_gtdb'] = value

        elif file.endswith('.gtdb.csv'):
            basename = file.replace('.gtdb.csv', '')
            full_path = os.path.join(folder, file)
            value = extract_f_unique_sum(full_path)
            data.setdefault(basename, {})['gtdb'] = value

    df_out = pd.DataFrame.from_dict(data, orient='index')
    df_out.index.name = 'basename'
    df_out.to_csv(output_csv)

# === Run on your folder:
process_sum(
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash_pangenome/gather',
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash_pangenome/250812_f_unique_weighted.gtdb_mags.pig.k31.csv'
)
