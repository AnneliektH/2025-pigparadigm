import os
import pandas as pd


# set list of samples
WORT_METAG = pd.read_csv("../resources/mag_created.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/sketches/MAG_sketch/{metag}_mags.sig', metag=WORT_METAG,),



rule gather_MAG_gtdb_reps:
    params:
        in_dir="/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/{metag}"
    output:
        sig = "../results/sketches/MAG_sketch/{metag}_mags.sig",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
        sourmash sketch dna {params.in_dir}/*.fasta \
        -p k=21,k=31,scaled=1000 \
        --name {wildcards.metag}_mag -o {output.sig}
    """

