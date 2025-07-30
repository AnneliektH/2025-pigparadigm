import os
import pandas as pd

# set db path 

ALL_MAG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all.merged.zip'
MAG95 = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.95.merged.zip'
MAG99 = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.99.merged.zip'

# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-hq.3217.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/sourmash/check/{metag}.mag_all.check', metag=WORT_METAG,),
        expand("../results/sourmash/check/{metag}.mag99.check", metag=WORT_METAG,),
        expand("../results/sourmash/check/{metag}.mag95.check", metag=WORT_METAG,),


rule gather_MAG:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash/gather/{metag}.mag_all.csv",
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
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash/gather/{metag}.mag95.csv",
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
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/sourmash/gather/{metag}.mag99.csv",
        check = "../results/sourmash/check/{metag}.mag99.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {MAG99} --create-empty-results \
       -k 21 --scaled 10000 -o {output.csv} && touch {output.check}
    """
