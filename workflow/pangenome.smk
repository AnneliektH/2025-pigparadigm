import os
import pandas as pd
import glob

# set dbs and other params
GTDB = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-reps-rs220-k21.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs220/gtdb-rs220.lineages.csv'
SMASH_TAX = '/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/taxonomy_MAGs.forsmash.csv'
OWN_MAG_SIG = '/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/sourmash/sketches/MAGs.all.s100.zip'
KSIZE = 31 
SCALED = 100

OUTPUT_DIR ="/group/ctbrowngrp2/amhorst/2025-pig-v-human/results/pangenome"
MAG_LOCATION = "/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/genomes"

# set configfile
configfile: "../config/config.yaml"
pangenome_species = config["pang_org"]
pang_name_out = config["pang_folder"]


# set the fasta files
# fasta_own = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{genome}.fasta").genome
fasta_gtdb = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fna.gz").sample
fasta_own = glob_wildcards(f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{sample}}.fasta").sample



# final output 
rule all:
    input:
        expand(f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{KSIZE}.{SCALED}.csv"),
        # expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{{genome}}.prokka.done", genome=fasta_gtdb),
        # expand(f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done"),


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
        fail_checksum= f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.checksum.failed.csv",
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
        --failed {output.failed_test} -r 1 --checksum-fail {output.fail_checksum}
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
        --norrna --notrna --prefix {wildcards.genome} \
        --locustag {wildcards.genome} {input.fa_own} && touch {output.check}
        """

# run prokka on the gtdb sequences (can i put these rules together?)
rule prokka_gtdb:
    input:
        fa_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/MAGs/{{genome}}.fna.gz",
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
        --norrna --notrna --prefix {wildcards.genome} \
        --locustag {wildcards.genome} {input.fa_gtdb} && touch {output.check}
        """

# run roary
rule roary:
    output:
        check = f"{OUTPUT_DIR}/{pang_name_out}/check/{pang_name_out}.roary.done",
    conda: 
        "roary"
    threads: 24
    params:
        prokka_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka",
        gff_folder = f"{OUTPUT_DIR}/{pang_name_out}/prokka/gff",
        output_folder=f"{OUTPUT_DIR}/{pang_name_out}/roary"
    shell:
        """ 
        mkdir -p {params.gff_folder} && \
        cp {params.prokka_folder}/*/*.gff {params.gff_folder} && \
        roary -p {threads} -f {params.output_folder} \
        -e -n -v {params.gff_folder}/*.gff && touch {output.check}
        """


# sourmash pangenome
rule sourmash_pangenome:
    input: 
        sig_gtdb = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.gtdb.zip"
    output:
        csv = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.picklist.csv",
        sig_own = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.ownmags.zip", 
        pang = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.pang.{KSIZE}.{SCALED}.sig.gz",
        rankt = f"{OUTPUT_DIR}/{pang_name_out}/sourmash/{pang_name_out}.rankt.{KSIZE}.{SCALED}.csv"
    conda: 
        "branchwater_skipmer"
    threads: 1
    shell:
        """ 
        sourmash tax grep -i "{pangenome_species}" \
        -t {SMASH_TAX} -o {output.csv} && \
        sourmash sig cat --picklist {output.csv}:ident:ident \
        {OWN_MAG_SIG} -o {output.sig_own} && \
        sourmash scripts pangenome_merge {input.sig_gtdb} {output.sig_own} -k {KSIZE} \
        -o {output.pang} --scaled {SCALED} && \
        sourmash scripts pangenome_ranktable {output.pang} -o {output.rankt} -k {KSIZE}
        """