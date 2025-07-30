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
        if file.endswith('.mags_and_gtdbreps.csv'):
            basename = file.replace('.mags_and_gtdbreps.csv', '')
            full_path = os.path.join(folder, file)
            value = extract_f_unique_sum(full_path)
            data.setdefault(basename, {})['mags_and_gtdbreps'] = value

        elif file.endswith('.gtdb_reps.csv'):
            basename = file.replace('.gtdb_reps.csv', '')
            full_path = os.path.join(folder, file)
            value = extract_f_unique_sum(full_path)
            data.setdefault(basename, {})['gtdb_reps'] = value

    df_out = pd.DataFrame.from_dict(data, orient='index')
    df_out.index.name = 'basename'
    df_out.to_csv(output_csv)

# === Run on your folder:
process_sum(
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/gather_human',
    '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sourmash/250716_f_unique_weighted.gtdb_mags.human.csv'
)
