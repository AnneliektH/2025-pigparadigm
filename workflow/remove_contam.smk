import os
import pandas as pd

# set ksize and genomes to map to
HUMAN_GENOME =  '/group/ctbrowngrp/sourmash-db/hg38/hg38-entire.sig.zip'
PIG_GENOME = '/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/resources/sus_scrofa/susScr11.sig.gz'
KSIZE = 21

# set configfile
configfile: "../config/config.yaml"

# Set samples for human and pig
metadata_human = pd.read_csv(config['human_SRA'], usecols=['acc'])
metadata_pig = pd.read_csv(config['pig_100'], usecols=['acc'])
metadata_pignm = pd.read_csv(config['pig_no_atlas'], usecols=['acc'])

# Create a list of run ids
samples_human = metadata_human['acc'].tolist()
samples_pig = metadata_pig['acc'].tolist()
samples_pignm = metadata_pignm['acc'].tolist()

# Define samples
HUMAN_METAG = config.get('samples', samples_human)
PIG_METAG = config.get('samples', samples_pig)
PIG_METAG_NM = config.get('samples', samples_pignm)
ALL_METAG = HUMAN_METAG + PIG_METAG +PIG_METAG_NM

# Human are in wort data, pig are in own sketch files, pig no mags are in wort
def get_input_file_path(metag):
    if metag in samples_human:
        return "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    elif metag in samples_pig:
        return "/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/sourmash/sketches/read_s100/{metag}.sig.gz"
    elif metag in samples_pignm:
        return "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig"
    else:
        raise ValueError(f"Unknown sample type: {metag}")

# Function to determine the output directory based on the sample type
def get_output_name(metag):
    if metag in samples_human:
        return "human"
    elif metag in samples_pig:
        return "pig"
    elif metag in samples_pignm:
        return "pig_nm"
    else:
        raise ValueError(f"Unknown sample type: {metag}")

# goal is to obtain clean signatures (no host contam)
rule all:
    input:
        expand('.../results/gather/{outputname}/{metag}.cleaned.csv', 
        outputname=[get_output_name(metag) for metag in PIG_METAG], metag=PIG_METAG,),
                expand('.../results/gather/{outputname}/{metag}.cleaned.csv', 
        outputname=[get_output_name(metag) for metag in PIG_METAG_NM], metag=PIG_METAG_NM,),
                expand('.../results/gather/{outputname}/{metag}.cleaned.csv', 
        outputname=[get_output_name(metag) for metag in HUMAN_METAG], metag=HUMAN_METAG,),
        # expand('../results/fmg_hostrm/concat/{metag}.gather.csv', metag=PIG_METAG,),


# concat the fmg output (once done against pig genome, once x human genome )
rule concat_fmg:
    input: 
        fmg_pig = "../results/fmg_hostrm/rmhuman/{metag}.gather.csv",
        fmg_human = "../results/fmg_hostrm/rmpig/{metag}.gather.csv"
    output: 
        csv_concat = "../results/fmg_hostrm/concat/{metag}.gather.csv"
    conda: 
        "csvtk"
    shell:
        """
        csvtk concat {input.fmg_pig} {input.fmg_human} > {output.csv_concat}
        """

# run a gather x this combined fastmultigather output
# output a signature with the matches removed, and a csv that keeps track of how much of the metaG = contamination
rule sig_rm_host:
# works
    input:
       sig = lambda wildcards: get_input_file_path(wildcards.metag),
       picklist = "../results/fmg_hostrm/concat/{metag}.gather.csv"
    output:
        sig = "../results/signatures/{outputname}/{metag}.sig.gz",
        csv = "../results/gather/{outputname}/{metag}.cleaned.csv",
    params:
        # Use the function to determine the output directory
        outputname=lambda wildcards: get_output_name(wildcards.metag)
    conda: 
        "branchwater"
    threads: 10
    shell:
        """ 
        sourmash gather {input.sig} {PIG_GENOME} {HUMAN_GENOME} \
        --picklist {input.picklist}:match_md5:md5 -o {output.csv} \
        -k {KSIZE} --scaled 1000 --output-unassigned {output.sig}
        """
