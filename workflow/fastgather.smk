import os
import pandas as pd

# set configfile
configfile: "../config/config.yaml"

# Set samples for human and pig
metadata_pig = pd.read_csv(config['readm_pig'], usecols=['acc'])
# Create a list of run ids
samples_pig = metadata_pig['acc'].tolist()

# Define samples
PIG_METAG = config.get('samples', samples_pig)
ATLAS_DIR = "/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/atlas"


rule all: 
    input:
        expand("../results/vir_fraction/fastgather/{metag}.csv", metag=PIG_METAG),

# compare to fastgather
rule fastgather_vir:  
# works
    input:
       sig = '../results/metag_sig/{metag}.zip',
       db = '../results/vir_fraction/hq_virseq.95.zip'
    output:
        csv = "../results/vir_fraction/fastgather/{metag}.csv",
    conda: 
        "branchwater"
    threads: 5
    shell:
        """ 
        sourmash scripts fastgather \
        {input.sig} {input.db} \
        -k 21 --scaled 100 -t 0 \
        -c {threads} -o {output.csv}
        """