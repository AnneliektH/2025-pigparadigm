# metaGs, only the ones that have a wort signature and contigs, will make sigs for the ones not in wort later
import pandas as pd


METAG = pd.read_csv("../resources/metag_with_contigs.txt", usecols=[0], header=None).squeeze().tolist()


ATLAS_DIR = "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/atlas"

rule all:
    input:
        expand("../results/containment/{sample}.x.mergedcontigs.manysearch.csv", sample=METAG),

rule sketch_contigs:
    input:
        fasta = f"{ATLAS_DIR}/atlas_{{sample}}/{{sample}}/{{sample}}_contigs.fasta", 
    output:
        sig="../results/containment/{sample}_contigs.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch dna {input.fasta} \
        -p k=21,k=31,scaled=1000 \
        --name {wildcards.sample}_contigs -o {output.sig}
        """

rule sig_search:
    input:
        contigs = "../results/containment/{sample}_contigs.zip", 
        metag = "../resources/wort-pig/{sample}.sig"
    output:
        csv="../results/containment/{sample}.x.contigs.manysearch.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash scripts manysearch {input.contigs} \
        {input.metag} -o {output.csv}
        """

rule sigmerged_search:
    input:
        contigs = "../results/containment/all_contigs.zip", 
        metag = "../resources/wort-pig/{sample}.sig"
    output:
        csv="../results/containment/{sample}.x.mergedcontigs.manysearch.csv",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash scripts manysearch {input.contigs} \
        {input.metag} -o {output.csv}
        """
