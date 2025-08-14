import os
import pandas as pd

# set db path 
MAGS = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/gtdb_pangenomedb/sra_mags.pangenomedb_species.10k.zip'
GTDB = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/gtdb_pangenomedb/gtdb-rs226.pangenomedb_species.10k.zip'
KSIZE =  31

# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-hq.3217.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
       # expand('../results/sourmash_pangenome/check_pig/{metag}.mags_and_gtdb.check', metag=WORT_METAG,),
        expand("../results/sourmash_pangenome/tax/check/{metag}.mags_and_gtdb.check", metag=WORT_METAG,),


rule gather_MAG_gtdb_reps:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash_pangenome/gather/{metag}.mags_and_gtdb.csv",
        check = "../results/sourmash_pangenome/check_pig/{metag}.mags_and_gtdb.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAGS} {GTDB} --create-empty-results --threshold-bp=0 \
       -k {KSIZE} --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_gtdb:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash_pangenome/gather/{metag}.gtdb.csv",
        check = "../results/sourmash_pangenome/check_pig/{metag}.gtdb.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {GTDB} --create-empty-results --threshold-bp=0 \
       -k {KSIZE} --scaled 10000 -o {output.csv} && touch {output.check}
    """

# tax metag slow, therefore maybe separate it?
rule tax_metag:
    input:
        csv="../results/sourmash_pangenome/gather/{metag}.mags_and_gtdb.csv",
        tax ="../results/gtdb_pangenomedb/250807_gtdb_sraMAGs.lineages.db"
    output:
        check = "../results/sourmash_pangenome/tax/check/{metag}.mags_and_gtdb.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash tax metagenome -g {input.csv} \
       --taxonomy {input.tax} -o {wildcards.metag} \
       --output-dir ../results/sourmash_pangenome/tax/individ && touch {output.check}
    """