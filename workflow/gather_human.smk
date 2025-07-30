import os
import pandas as pd

# set db path 
ALL_MAG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all.merged.zip'
MAG95 = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.95.merged.zip'
MAG99 = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.99.merged.zip'
MAGS = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all.rocksdb'
#GTDB = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226.k21.rocksdb'
GTDB = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.k21.rocksdb'



# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-human-exist.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        # expand('../results/sourmash_human/check/{metag}.animal_plant.k51.check', metag=WORT_METAG,),
        # expand('../results/sourmash/check/{metag}.mag95.check', metag=WORT_METAG,),
        # expand('../results/sourmash/check/{metag}.mag99.check', metag=WORT_METAG,),
        # expand('../results/sourmash/check/{metag}.mag_all.check', metag=WORT_METAG,),
        expand('../results/sourmash/check/{metag}.mags_and_gtdbreps.check', metag=WORT_METAG,),
        expand('../results/sourmash/check/{metag}.gtdb_reps.check', metag=WORT_METAG,),
        
        


rule gather_MAG:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/sourmash/gather_human/{metag}.mag_all.csv",
        check = "../results/sourmash/check/{metag}.mag_all.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {ALL_MAG} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_MAG95:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/sourmash/gather_human/{metag}.mag95.csv",
        check = "../results/sourmash/check/{metag}.mag95.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAG95} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_MAG99:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/sourmash/gather_human/{metag}.mag99.csv",
        check = "../results/sourmash/check/{metag}.mag99.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAG99} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_MAG_gtdb_reps:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/sourmash/gather_human/{metag}.mags_and_gtdbreps.csv",
        check = "../results/sourmash/check/{metag}.mags_and_gtdbreps.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAGS} {GTDB} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """

rule gather_gtdb:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    output:
        csv = "../results/sourmash/gather_human/{metag}.gtdb_reps.csv",
        check = "../results/sourmash/check/{metag}.gtdb_reps.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {GTDB} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """