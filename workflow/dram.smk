# imports
import os
import pandas as pd

# Load the metadata file
metadata = pd.read_csv('config/MAGs_w_array.txt', usecols=['MAG'])
# Create a list of run ids
samples = metadata['MAG'].tolist()
# Define samples
SAMPLES = config.get('samples', samples)

rule all:
    input:
        expand("../results/DRAM/check/{sample}.check", sample=SAMPLES),
# run dram
rule DRAM:
    input:
        fasta = '/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/all_genomes/{sample}.fasta', 
    output:
        txt='../results/DRAM/check/{sample}.check',
    conda: 
        "DRAM"
    # params:
    #     input_folder = '/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/{sample}
    threads: 24
    shell:
        """
        DRAM.py annotate -i {input.fasta} --skip_trnascan --threads {threads} \
        --output_dir ../results/DRAM/{wildcards.sample} && touch {output.txt}
        """

# rule DRAM_distill:
#     input:
#         fasta = '/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/{sample}/*.fasta', 
#     output:
#         txt='../results/DRAM/check/{ident}.done',
#     conda: 
#         "DRAM"
#     threads: 12
#     shell:
#         """
#         DRAM.py distill -i {input.fasta} \
#         --output_dir ../results/DRAM/{wildcards.fasta}
#         """


