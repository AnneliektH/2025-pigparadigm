import pandas as pd
import glob, os

GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226s.lineages.csv'
NEW_MAG_TAX = '../resources/250703_mag_taxonomy.tsv'
KSIZE = 21 
SCALED = 1000
OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/branchwater"
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
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/check/symlink.check", pang_folder=pang_folders),
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.zip", pang_folder=pang_folders),
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip", pang_folder=pang_folders), 


# rule get_mags_of_interest:
#     output:
#         tsv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.tsv",
#         csv_temp = temp(f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb_temp.csv"),
#         csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv"
#     conda:
#         "branchwater-skipmer"
#     threads: 1
#     params:
#         species=lambda w: get_species(w.pang_folder)
#     shell:
#         """
#         (head -n 1 {NEW_MAG_TAX} && grep -e "{params.species}" {NEW_MAG_TAX}) > {output.tsv} && \
#         (head -n 1 {GTDB_TAX} && grep -e "{params.species}" {GTDB_TAX}) > {output.csv_temp} && \
#         python scripts/create_acc.py {output.csv_temp} {output.csv}
#         """

rule get_mags_of_interest_v2:
    output:
        tsv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.tsv",
        csv_temp = temp(f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb_temp.csv"),
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv"
    conda:
        "branchwater-skipmer"
    threads: 1
    params:
        species=lambda w: get_species(w.pang_folder)
    shell:
        """
        awk -F'\t' -v sp="{params.species}" 'NR==1 || $NF == sp' {NEW_MAG_TAX} > {output.tsv} && \
        awk -F',' -v sp="{params.species}" 'NR==1 || $NF == "s__" sp' {GTDB_TAX} > {output.csv_temp} && \
        python scripts/create_acc.py {output.csv_temp} {output.csv}
        """


rule directsketch:
    input:
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv"
    output:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.zip",
        failed_test = f"{OUTPUT_DIR}/{{pang_folder}}/check/{{pang_folder}}.failed.csv",
        fail_checksum= f"{OUTPUT_DIR}/{{pang_folder}}/check/{{pang_folder}}.checksum.failed.csv",
    conda: "branchwater-skipmer"
    threads: 32
    params:
        output_folder=lambda w: f"{OUTPUT_DIR}/{w.pang_folder}/MAGs"
    shell:
        """
        sourmash scripts gbsketch --keep-fasta --genomes-only \
        {input.csv} -o {output.sig} -p dna,k=21,k=31,scaled=1000,abund \
        -f {params.output_folder} -k -c {threads} -n 5 \
        --failed {output.failed_test} -r 5 --checksum-fail {output.fail_checksum}
        for f in {params.output_folder}/*.fna.gz; do
            mv "$f" "${{f%.fna.gz}}.fasta"
        done
        """

rule symlink_MAGs:
    input:
        tsv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.tsv"
    output:
        check = f"{OUTPUT_DIR}/{{pang_folder}}/check/symlink.check"
    conda: "branchwater-skipmer"
    threads: 1
    params:
        output_folder=lambda w: f"{OUTPUT_DIR}/{w.pang_folder}/MAGs"
    shell:
        """
        python scripts/create_symlink_args.py {input.tsv} {MAG_LOCATION} {params.output_folder} && \
        touch {output.check}
        """

rule sketch_own_mags:
    input:
        tsv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.tsv"
    output:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip"
    conda: "branchwater-skipmer"
    threads: 1
    params:
        in_folder=lambda w: f"{OUTPUT_DIR}/{w.pang_folder}/MAGs"
    shell:
        """
        sourmash sketch dna {params.in_folder}/AtH*.fasta \
        -p k=21,k=31,scaled=1000 \
        -o {output.sig}
        """

