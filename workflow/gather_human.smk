import os
import pandas as pd

# set db path 
ALL_MAG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all_k31.merged.rocksdb'
GTDB = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/gtdb_pangenomedb/gtdb-rs226.merged_k31.rocksdb'



# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-human-good.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand("../results/gtdb_pangenomedb/gather_k31/{metag}.mags_and_gtdbreps.csv", metag=WORT_METAG,),
        
    
rule gather_MAG_gtdb_reps:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/gtdb_pangenomedb/gather_k31/{metag}.mags_and_gtdbreps.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {ALL_MAG} {GTDB} --create-empty-results \
       -k 31 --scaled 10000 -o {output.csv} --threshold-bp 0
    """

