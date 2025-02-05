import os
import pandas as pd

# set dbs and other params
GTDB = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-reps-rs220-k21.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-rs220.lineages.csv'
KSIZE = 21 
OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pig-v-human/results/pangenome"
MAG_LOCATION = "/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/genomes"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]


# set the fasta files
# fasta_own = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{genome}.fasta").genome
# fasta_gtdb = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{genome}.fna.gz").genome
fasta_own = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fasta").sample

# final output 
rule all:
    input:
        #expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip"),
        expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done", genome=fasta_own),


# get lists of MAGs that are org of interest
rule get_mags_of_interest:
    input:
        own_tsv = "/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/240705_genome_taxonomy.tsv",
        #pangenome_species = pangenome_species,
    output:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        csv_temp = temp(f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb_temp.csv"),
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """ 
        (head -n 1 {input.own_tsv} && grep -e "{pangenome_species}" {input.own_tsv}) > {output.tsv} && \
        (head -n 1 {GTDB_TAX} && grep -e "{pangenome_species}" {GTDB_TAX}) > {output.csv_temp} && \
        python scripts/create_acc.py {output.csv_temp} {output.csv}
        """

# symlink MAGs from own metaGs into a folder
rule symlink_MAGs:
    input:
        tsv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xownmags.tsv",
        #pangenome_species = pangenome_species,
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/symlink.check",
    conda: 
        "branchwater-skipmer"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        python scripts/create_symlink_args.py {input.tsv} {MAG_LOCATION} {params.output_folder} && \
        touch {output.check}
        """

# download MAGs from NCBI with directsketch
rule directsketch:
    input:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/{pang_name_out}xgtdb.csv",
    output:
        sig = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip",
        failed_test = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.failed.csv",
    conda: 
        "branchwater-skipmer"
    threads: 10
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/MAGs"
    shell:
        """ 
        sourmash scripts gbsketch  --keep-fasta --genomes-only \
        {input.csv} -o {output.sig} -p dna,k=21,k=31,scaled=100,abund \
        -f {params.output_folder} -k -c {threads} \
        --failed {output.failed_test} -r 1
        """
# run prokka
rule prokka:
    input:
        fa_own = f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{genome}}.fasta",
        #fa_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{genome}}.fna.gz",
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done",
    conda: 
        "prokka"
    threads: 1
    params:
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/prokka/{{genome}}"
    shell:
        """ 
        prokka --kingdom Bacteria --outdir {params.output_folder} \
        --norrna --notrna \
        --locustag {wildcards.genome} {input.fa_own} && touch {output.check}
        """


# run roary

# get signatures of org of interest (sourmash pangenome)

# sourmash pangenome



rule sig_rm_host:
    input:
        sig = "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        picklist = "../results/sourmash/sketches/read_pig_nomag/concat/{metag}.gather.csv",
    output:
        sig = "../results/sourmash/sketches/read_pig_nomag/hostrm/{metag}.zip",
        csv='../results/sourmash/con_removal/{metag}.csv'
    conda: 
        "branchwater"
    threads: 1
    shell:
        """ 
        sourmash gather {input.sig} {PIG_GENOME} {HUMAN_GENOME} \
        --picklist {input.picklist}:match_md5:md5 -o {output.csv} \
        -k {KSIZE} --scaled 1000 --output-unassigned {output.sig}
        """


