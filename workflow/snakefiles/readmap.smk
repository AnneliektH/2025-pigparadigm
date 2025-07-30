import os
import pandas as pd

# set configfile
configfile: "../config/config.yaml"

# Set samples for human and pig
metadata_pig = pd.read_csv(config['amr_pig'], usecols=['acc'])
# Create a list of run ids
samples_pig = metadata_pig['acc'].tolist()

# Define samples
PIG_METAG = config.get('samples', samples_pig)
ATLAS_DIR = "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/atlas"


rule all: 
    input:
        expand("../results/bowtie2/MAGmapping/{metag}.bam", metag=PIG_METAG),

rule bowtie:
    input:
        fw = f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz", 
        rv = f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
    output:
        samfile = temporary("../results/bowtie2/MAGmapping/{metag}.sam"),
    conda: 
        "bowtie2"
    threads: 10
    shell:
        """
        bowtie2 --threads {threads} \
        -x ../results/bowtie2/MAGs_95 \
        -1 {input.fw} -2 {input.rv} \
        -S {output.samfile} --no-unal --sensitive
        """

rule samtools:
    input:
        samfile = temporary("../results/bowtie2/MAGmapping/{metag}.sam"),
    output:
        bamfile = "../results/bowtie2/MAGmapping/{metag}.bam",
    conda: 
        "samtools"
    threads: 5
    shell:
        """
        samtools view -@ {threads} -F 4 -bS {input.samfile} | samtools sort > {output.bamfile} && \
        samtools index {output.bamfile} 
        """

