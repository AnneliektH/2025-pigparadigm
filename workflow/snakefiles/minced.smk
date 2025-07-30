# imports 
import os
import pandas as pd

# all genomes
FASTA, = glob_wildcards('/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/all_genomes/{ident}.fasta')

rule all:
    input:
        expand("../results/crispr/minced/{ident}.txt", ident=FASTA),

rule minced:
    input:
        fasta = '/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/all_genomes/{ident}.fasta', 
    output:
        txt='../results/crispr/minced/{ident}.txt',
    conda: 
        "minced"
    threads: 1
    shell:
        """
        minced -spacers {input.fasta} {output.txt}
        """
