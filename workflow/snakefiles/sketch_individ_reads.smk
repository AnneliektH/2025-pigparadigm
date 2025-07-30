import os
import pandas as pd


# def atlas dir 
ATLAS_DIR = "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/atlas"

# set configfile
configfile: "../config/config.yaml" 
# Set samples for human and pig
metadata_metag = pd.read_csv(config['amr_pig'], usecols=['acc'])
# Create a list of run ids
samples_pig = metadata_metag['acc'].tolist()
# Define samples
PIG_METAG = config.get('samples', samples_pig)


rule all:
    input:
        expand("../results/sketches_metag/{metag}_r1.zip", metag=PIG_METAG),
        expand("../results/sketches_metag/{metag}_r2.zip", metag=PIG_METAG),
        expand("../results/sketches_metag/{metag}_merge.zip", metag=PIG_METAG)



# Use all
rule sketch_r1:
    input:
        read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
    output:
        sketch = "../results/sketches_metag/{metag}_r1.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: 
        """
        sourmash sketch dna {input.read_one} \
        -p k=21,scaled=100,abund \
        --name {wildcards.metag}_r1 -o {output.sketch}
        """

# Use all
rule sketch_r2:
    input:
        read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
    output:
        sketch = "../results/sketches_metag/{metag}_r2.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: 
        """
        sourmash sketch dna {input.read_two} \
        -p k=21,scaled=100,abund \
        --name {wildcards.metag}_r2 -o {output.sketch}
        """
rule sketch_m:
    input:
        read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
        read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
    output:
        sketch = "../results/sketches_metag/{metag}_merge.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: 
        """
        sourmash sketch dna {input.read_one} {input.read_two} \
        -p k=21,scaled=100,abund \
        --merge {wildcards.metag}_merge -o {output.sketch}
        """