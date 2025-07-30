import glob
import pandas as pd

# set configfile
configfile: "../config/config.yaml"
metadata_pig = pd.read_csv(config['pig_test'], usecols=['acc'])
samples_pig = metadata_pig['acc'].tolist()
PIG_METAG = config.get('samples', samples_pig)


def get_mag_proteins(metag):
    sample = metag
    path = f"/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/atlas/atlas_{sample}/genomes/annotations/genes/"
    protein_files = glob.glob(f"{path}*.faa")
    return protein_files

def get_outputname(metag):
    sample = metag
    path = f"/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/atlas/atlas_{sample}/genomes/annotations/genes/"
    protein_files = glob.glob(f"{path}*.faa")
    filenames = [os.path.splitext(os.path.basename(f))[0] for f in protein_files]
    return filenames


rule all:
    input:
        expand('../results/done/{metag}.blastp.txt', metag= PIG_METAG)


# rule do something with the protien files
rule protein_blast:
    input: 
        proteins = lambda wildcards: get_mag_proteins(wildcards.metag),
        #db = 'db'
    output: 
        csv = "../results/done/{metag}.blastp.txt"
    params:
        # Use the function to determine the output directory
        outputname=lambda wildcards: get_outputname(wildcards.metag)
    conda: 
        "csvtk"
    threads: 4
    shell:
        """
        for p in {input.proteins}; do
            for f in {params.outputname}; do
                diamond blastp --in "$p" --out path/to/out/"$f".csv 
                echo "$p"
                echo "$f"
            done
        done

        touch {output.csv}
        """
