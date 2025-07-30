import os
import pandas as pd

# set db path 
MAGS = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all.rocksdb'
# MAGS_PANG = /group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all.merged.zip
# GTDB_PANGENOME = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.pangenomedb.10k.zip'
GTDB = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.k21.rocksdb'


# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-hq.3217.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/sourmash/check_pig/{metag}.mags_and_gtdbreps.check', metag=WORT_METAG,),
        expand("../results/sourmash/check_pig/{metag}.gtdb_reps.check", metag=WORT_METAG,),


rule gather_MAG_gtdb_reps:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash/gather/{metag}.mags_and_gtdbreps.csv",
        check = "../results/sourmash/check_pig/{metag}.mags_and_gtdbreps.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAGS} {GTDB} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_gtdb:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash/gather/{metag}.gtdb_reps.csv",
        check = "../results/sourmash/check_pig/{metag}.gtdb_reps.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {GTDB} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """