import pandas as pd
import glob, os


GTDB_K21 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k21.sig.zip'
GTDB_K31 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k31.sig.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.lineages.csv'
MAG_TAX = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/250827_taxfor_sourmash.gtdb226.csv'
OWN_MAG_SIG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all_taxed.zip'
# KSIZE = 31 
SCALED = 1000
OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/functional_profile_corespp"
MAG_LOCATION = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes"

genomes_all = glob_wildcards(f"{OUTPUT_DIR}/{{pang_folder}}/MAGs/{{sample}}.fasta").sample


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
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/fasta/{{pang_folder}}.gtdb.zip", pang_folder=pang_folders),
        expand(f"{OUTPUT_DIR}/{{pang_folder}}/funcprofiler/{{genome}}.prefetch.csv", pang_folder=pang_folders, genome=genomes_all),

# Get MAGs from specific speices 
rule get_species_mags:
    output:
        csvown = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.csv",
        csvgtdb = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv",
    conda:
        "branchwater-skipmer" 
    threads: 1
    params:
        species=lambda w: get_species(w.pang_folder)
    shell:
        """
        python scripts/250903_extract_lineages.py {GTDB_TAX} "{params.species}" {output.csvgtdb} && \
        python scripts/250903_extract_lineages.py {MAG_TAX} "{params.species}" {output.csvown} --add-fasta
        """

rule get_MAGS:
    input:
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv",
    output:
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xdirectsketch.csv",
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/fasta/{{pang_folder}}.gtdb.zip",
        failed_test = f"{OUTPUT_DIR}/{{pang_folder}}/check/{{pang_folder}}.failed.csv",
        fail_checksum= f"{OUTPUT_DIR}/{{pang_folder}}/check/{{pang_folder}}.checksum.failed.csv",
    conda: 
        "branchwater-skipmer" 
    threads: 10
    params:
        output_folder=f"{OUTPUT_DIR}/{{pang_folder}}/MAGs"
    shell:
        """
        python scripts/create_acc.py {input.csv} {output.csv} && \
        sourmash scripts gbsketch  --keep-fasta --genomes-only \
        {output.csv} -o {output.sig} -p dna,k=21,k=31,scaled=100,abund \
        -f {params.output_folder} -k -c {threads} -n 5 \
        --failed {output.failed_test} -r 5 --checksum-fail {output.fail_checksum}
        for f in {params.output_folder}/*.fna.gz; do
            mv "$f" "${{f%.fna.gz}}.fasta"
        done
        """
# symlink pig-specific MAGs
rule symlink_MAGs:
    input:
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.csv",
    output:
        check = f"{OUTPUT_DIR}/{{pang_folder}}/check/symlink.check",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{{pang_folder}}/MAGs"
    shell:
        """ 
        python scripts/create_symlink_args.py {input.csv} {MAG_LOCATION} {params.output_folder} && \
        touch {output.check}
        """

rule funcprofiler_MAGs:
    input:
        genomes= f"{OUTPUT_DIR}/{{pang_folder}}/MAGs/{{genome}}.fasta",
    output:
        csv = f"{OUTPUT_DIR}/{{pang_folder}}/funcprofiler/{{genome}}.prefetch.csv",
    conda: 
        "branchwater"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{{pang_folder}}/funprofiler",
    shell:
        """ 
        python funprofiler/funcprofiler.py \
        {input.genomes} \
        /group/ctbrowngrp2/amhorst/2025-pigparadigm/databases/KOs_sketched_scaled_1000.sig.zip \
        11 1000 {params.output_folder} -p {output.csv}
        """