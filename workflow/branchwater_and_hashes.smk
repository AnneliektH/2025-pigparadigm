import pandas as pd
import glob, os


GTDB_K21 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k21.sig.zip'
GTDB_K31 = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.k31.sig.zip'
GTDB_TAX  = '/group/ctbrowngrp/sourmash-db/gtdb-rs226/gtdb-rs226.lineages.csv'
MAG_TAX = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/250827_taxfor_sourmash.gtdb226.csv'
OWN_MAG_SIG = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.all_taxed.zip'
# KSIZE = 31 
SCALED = 1000
OUTPUT_DIR = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/branchwater"
METAPG_OUT = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/metapangenome"
MAG_LOCATION = "/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes"
SUFFIXES = ["ownmagsmerged.k31", "gtdbmerged.k31", "unique_own.k31"]
WORT_METAG = pd.read_csv("../resources/metag-wort-hq.3217.txt", usecols=[0], header=None).squeeze().tolist()


# Load pang_org list
pang_df = pd.read_csv("../resources/pang_list.csv")  # Only needs 'pang_org' column

# Create pang_folder by replacing spaces with underscores
pang_df["pang_folder"] = pang_df["pang_org"].str.replace(" ", "_")

pang_folders = pang_df["pang_folder"].tolist()

def get_species(pang_folder):
    return pang_df.loc[pang_df["pang_folder"] == pang_folder, "pang_org"].item()


rule all:
    input:
        #expand(f"{METAPG_OUT}/{{pang_folder}}_counts/{{metag}}.k21.csv", pang_folder=pang_folders, metag=WORT_METAG),
        expand(f"{METAPG_OUT}/sum_count/{{pang_folder}}.k21.metag_counts.csv", pang_folder=pang_folders),
        #  expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sizes.tsv", pang_folder=pang_folders)
        # expand(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sramags.zip", pang_folder=pang_folders), 


rule sum_hashes_found:
    input:
        rankt = f"{METAPG_OUT}/ranktables/{{pang_folder}}.rankt.k21.csv",
    output:
        csv = f"{METAPG_OUT}/sum_count/{{pang_folder}}.k21.metag_counts.csv",
    conda: "pangenomics_dev"
    params:
        input_folder = f"{METAPG_OUT}/{{pang_folder}}_counts"
    threads: 1
    shell:
        """
        python scripts/sum_hashval.py {params.input_folder} {output.csv}
        """

rule hashtable:
    input:
        query = "../resources/wort-pig/{metag}.sig",
        rankt = f"{METAPG_OUT}/ranktables/{{pang_folder}}.rankt.k21.csv",
    output:
        csv = f"{METAPG_OUT}/{{pang_folder}}_counts/{{metag}}.k21.csv",
    conda: "pangenomics_dev"
    threads: 1
    shell:
        """
        sourmash scripts hash_tables {input.rankt} \
       {input.query} -o {output.csv} -k 21 --scaled 1000
        """

# Use the merged signature to make ranktable
rule ranktable:
    input:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.merge.k21.zip",
    output:
        rankt = f"{METAPG_OUT}/ranktables/{{pang_folder}}.rankt.k21.csv",
    conda: "pangenomics_dev"
    threads: 1
    shell:
        """
        sourmash scripts pangenome_ranktable -k 21 {input.sig} -o {output.rankt}
        """
# branchwater client
rule branchwater:
    input:
        sig = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.merge.k21.sig",
    output:
        csv = f"{OUTPUT_DIR}/branchwater_analysis/{{pang_folder}}.branchw.csv",
    conda: "branchwater"
    threads: 1
    shell:
        """
        branchwater-client --full --sig {input.sig} -o {output.csv}
        """
# Get MAGs from specific speices 
rule get_species_mags:
    output:
        csvown = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.csv",
        csvgtdb = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv",
    conda:
        "branchwater-skipmer"
    threads: 1
    params:
        species=lambda w: get_species(w.pang_folder)
    shell:
        """
        python scripts/250903_extract_lineages.py {GTDB_TAX} "{params.species}" {output.csvgtdb} && \
        python scripts/250903_extract_lineages.py {MAG_TAX} "{params.species}" {output.csvown} --add-fasta
        """
# sig grep all genomes from species into new sig
rule sig_grep:
    input:
        csvown = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xownmags.csv",
        csvgtdb = f"{OUTPUT_DIR}/{{pang_folder}}/{{pang_folder}}xgtdb.csv",
    output:
        sig_gtdb_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.k21.zip",
        sig_own_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmags.k21.zip",
        sig_gtdb_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.k31.zip",
        sig_own_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmags.k31.zip",
    conda: "branchwater-skipmer"
    threads: 32
    shell:
        """
        sourmash sig extract --picklist {input.csvgtdb}:ident:ident {GTDB_K21} -o {output.sig_gtdb_k21} -k 21 && \
        sourmash sig extract --picklist {input.csvown}:ident:ident {OWN_MAG_SIG} -o {output.sig_own_k21} -k 21 && \
        sourmash sig extract --picklist {input.csvgtdb}:ident:ident {GTDB_K31} -o {output.sig_gtdb_k31} -k 31 && \
        sourmash sig extract --picklist {input.csvown}:ident:ident {OWN_MAG_SIG} -o {output.sig_own_k31} -k 31
        """
# subtract
rule subtract:
    input:
        sig_gtdb_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.k31.zip",
        sig_own_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmags.k31.zip",
    output:
        sig_gtdb_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdbmerged.k31.zip",
        sig_own_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmagsmerged.k31.zip",
        sig_sub = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.unique_own.k31.zip",
    conda: "branchwater-skipmer"
    threads: 32
    shell:
        """
        sourmash sig merge {input.sig_own_k31} --flatten -k 31 -o {output.sig_own_k31} && \
        sourmash sig merge {input.sig_gtdb_k31} --flatten -k 31 -o {output.sig_gtdb_k31} && \
        sourmash sig subtract {output.sig_own_k31} {output.sig_gtdb_k31} -o {output.sig_sub} -k 31
        """
# merge k21
rule merge:
    input:
        sig_gtdb_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdb.k21.zip",
        sig_own_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmags.k21.zip",
    output:
        sig_gtdb_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdbmerged.k21.zip",
        sig_own_k21 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmagsmerged.k21.zip",
        sig_merge = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.merge.k21.sig",
    conda: "branchwater-skipmer"
    threads: 32
    shell:
        """
        sourmash sig merge {input.sig_own_k21} --flatten -k 21 -o {output.sig_own_k21} && \
        sourmash sig merge {input.sig_gtdb_k21} --flatten -k 21 -o {output.sig_gtdb_k21} && \
        sourmash sig merge {output.sig_gtdb_k21} {output.sig_own_k21} -o {output.sig_merge} -k 21
        """
# get signature sizes
rule get_sig_size:
    input:
        f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.{{suffix}}.zip"
    output:
        temp(f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.{{suffix}}.size.txt")
    conda: "branchwater-skipmer"
    shell:
        """
        sourmash sig describe {input} \
          | awk '/^size:/{{print $2}}' > {output}
        """
# put sizes into csv output file
rule aggregate_hash_sizes:
    input:
        lambda wildcards: expand(
            f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.{{suffix}}.size.txt",
            pang_folder=wildcards.pang_folder,
            suffix=SUFFIXES
        )
    output:
        f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.sizes.tsv"
    run:
        sizes = {}
        for inp, suffix in zip(input, SUFFIXES):
            with open(inp) as f:
                sizes[suffix] = f.read().strip()
        with open(output[0], "w") as out:
            out.write("species\t" + "\t".join(SUFFIXES) + "\n")
            out.write(f"{wildcards.pang_folder}\t" + "\t".join(sizes[s] for s in SUFFIXES) + "\n")
# merge k31
rule merge_k31:
    input:
        sig_gtdb_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.gtdbmerged.k31.zip",
        sig_own_k31 = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.ownmagsmerged.k31.zip",
    output:
        merge = f"{OUTPUT_DIR}/{{pang_folder}}/sourmash/{{pang_folder}}.merged.k31.zip",
    conda: "branchwater-skipmer"
    threads: 32
    shell:
        """
        sourmash sig merge {input.sig_own_k31} {input.sig_gtdb_k31} -k 31 -o {output.merge}
        """
