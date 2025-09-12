import pandas as pd
import glob, os


GTDB_K21 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k21.sig.zip'
GTDB_K31 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k31.sig.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.lineages.csv'
MAG_TAX = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/250827_taxfor_sourmash.gtdb226.csv'
OWN_MAG_SIG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all_taxed.zip'
# KSIZE = 31 
SCALED = 1000
OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/branchwater"
METAPG_OUT = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/metapangenome"
MAG_LOCATION = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes"


# Load pang_org list
pang_df = pd.read_csv("../resources/pang_list.csv")  # Only needs 'pang_org' column

# Create pang_folder by replacing spaces with underscores
pang_df["pang_folder"] = pang_df["pang_org"].str.replace(" ", "_")

pang_folders = pang_df["pang_folder"].tolist()

def get_species(pang_folder):
    return pang_df.loc[pang_df["pang_folder"] == pang_folder, "pang_org"].item()


rule all:
    input:
        expand(f"{OUTPUT_DIR}/branchwater_analysis/{{pang_folder}}.branchw.csv", pang_folder=pang_folders),
        #expand(f"{METAPG_OUT}/branchwater_analysis/{{pang_folder}}.branchw_corehash.csv", pang_folder=pang_folders)
        # expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip", pang_folder=pang_folders), 


# branchwater client
rule branchwater:
    input:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.merge.k21.sig",
    output:
        csv = f"{OUTPUT_DIR}/branchwater_analysis/{{pang_folder}}.branchw.csv",
    conda: "branchwater"
    threads: 1
    shell:
        """
        branchwater-client --full --sig {input.sig} -o {output.csv} 
        """

rule branchwater_corehash:
    input:
        sig = f"{METAPG_OUT}/sum_count/{{pang_folder}}.k21.metag_counts.zip",
    output:
        sig = f"{METAPG_OUT}/sum_count/{{pang_folder}}.k21.metag_counts.sig",
        csv = f"{METAPG_OUT}/branchwater_analysis/{{pang_folder}}.branchw_corehash.csv",
    conda: "branchwater"
    threads: 1
    shell:
        """
        sourmash sig cat {input.sig} -o {output.sig}
        branchwater-client --full --sig {output.sig} -o {output.csv}
        """