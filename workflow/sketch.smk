import os
import pandas as pd


# def outdir
ATLAS_DIR = "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/atlas"

# set configfile
configfile: "../config/config.yaml" 
# Set samples for human and pig
metadata_metag = pd.read_csv(config['all_pig_atlas'], usecols=['acc'])
# Create a list of run ids
samples_pig = metadata_metag['acc'].tolist()
# Define samples
PIG_METAG = config.get('samples', samples_pig)


rule all:
    input:
        #expand("../results/compare_all/check/{metag}.rgi.{aligner}.done", metag=PIG_METAG, aligner=ALIGNERS),
        expand("../results/metag_signatures/{metag}.zip", metag=PIG_METAG),
        # expand("../results/metag_sig_gz/manysketch_csv/{metag}.csv", metag=PIG_METAG),
        # expand("../results/metag_sig_gz/check/{metag}.done", metag=PIG_METAG),
        # expand("../results/sketches_metag/{metag}_r2.zip", metag=PIG_METAG),



# rule sketch:
#     input:
#         read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
#         read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
#     output:
#         sketch = "../results/metag_signatures/{metag}.zip",
#     conda: 
#         "branchwater-skipmer"
#     threads: 1
#     shell: 
#         """
#         sourmash sketch dna {input.read_one} {input.read_two} \
#         -p k=21,k=31,k=51,scaled=1000,abund \
#         --name {wildcards.metag} -o {output.sketch}
#         """


# singlesketch may be faster 
rule singlesketch:
    input:
        read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
        read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
    output:
        sig = "../results/metag_signatures/{metag}.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: 
        """
        sourmash scripts singlesketch {input.read_one} {input.read_two} \
        -p k=21,k=31,k=51,scaled=1000,abund \
        --name {wildcards.metag} -o {output.sig}
        """

# rule manysketch:
#     input:
#         csv="../results/metag_sig_gz/manysketch_csv/{metag}.csv",
#     output:
#         sketch = "../results/metag_sig_gz/{metag}.sig.gz",
#         check = "../results/metag_sig_gz/check/{metag}.done",
#     conda: 
#         "branchwater-skipmer"
#     threads: 4
#     shell: 
#         """
#         sourmash scripts manysketch -c {threads} \
#         {input.csv} -o {output.sketch} -p dna,k=21,k=31,k=51,scaled=100,abund \
#         && touch {output.check}
#         """

# rule manysketch:
#     input:
#         csv="../results/metag_sig_gz/manysketch_csv/{metag}.csv",
#     output:
#         sketch = "../results/metag_sig_gz/{metag}.sig.gz",
#         check = "../results/metag_sig_gz/check/{metag}.done",
#     conda: 
#         "branchwater-skipmer"
#     threads: 4
#     shell: 
#         """
#         sourmash scripts manysketch -c {threads} \
#         {input.csv} -o {output.sketch} -p dna,k=21,k=31,k=51,scaled=100,abund \
#         && touch {output.check}
#         """




# Use all


# # # Use all
# # rule sketch_r1:
#     input:
#         read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
#     output:
#         sketch = "../results/sketches_metag/{metag}_r1.zip",
#     conda: 
#         "branchwater-skipmer"
#     threads: 1
#     shell: 
#         """
#         sourmash sketch dna {input.read_one} \
#         -p k=21,scaled=100,abund \
#         --name {wildcards.metag} -o {output.sketch}
#         """

# # Use all
# rule sketch_r2:
#     input:
#         read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
#     output:
#         sketch = "../results/sketches_metag/{metag}_r2.zip",
#     conda: 
#         "branchwater-skipmer"
#     threads: 1
#     shell: 
#         """
#         sourmash sketch dna {input.read_two} \
#         -p k=21,scaled=100,abund \
#         --name {wildcards.metag} -o {output.sketch}
#         """
# rule sketch_m:
#     input:
#         read_one=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R1.fastq.gz",
#         read_two=f"{ATLAS_DIR}/atlas_{{metag}}/{{metag}}/sequence_quality_control/{{metag}}_QC_R2.fastq.gz",
#     output:
#         sketch = "../results/sketches_metag/{metag}_merge.zip",
#     conda: 
#         "branchwater-skipmer"
#     threads: 1
#     shell: 
#         """
#         sourmash sketch dna {input.read_one} {input.read_two} \
#         -p k=21,scaled=100,abund \
#         --merge {wildcards.metag} -o {output.sketch}
#         """