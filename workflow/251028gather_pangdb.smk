import os
import pandas as pd

# set db path 
DB = '/home/ctbrown/scratch3/sourmash-midgie-raker/outputs.ath/host/clean-gtdb+bins.species.k31.rocksdb'
KSIZE =  31

# set list of samples
WORT_METAG = pd.read_csv("../resources/metag-wort-hq.3217.txt", usecols=[0], header=None).squeeze().tolist()


rule all:
    input:
        expand("../results/clean-gatherxgtdb+bins.species/check_pig/{metag}.check", metag=WORT_METAG,),


rule gather:
    input:
        query="../resources/wort-pig/{metag}.sig"
    output:
        csv = "../results/clean-gatherxgtdb+bins.species/{metag}.csv",
        check = "../results/clean-gatherxgtdb+bins.species/check_pig/{metag}.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {DB} --create-empty-results --threshold-bp=0 \
       -k {KSIZE} --scaled 1000 -o {output.csv} && touch {output.check}
    """
