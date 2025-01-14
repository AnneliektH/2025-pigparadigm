# concat the fmg output from against human and against pig
rule concat_fmg:
    input: 
        fmg_pig = "../results/sourmash/sketches/read_pig_nomag/fmg/rmpig/{metag}.gather.csv",
        fmg_human = "../results/sourmash/sketches/read_pig_nomag/fmg/rmhuman/{metag}.gather.csv"
    output: 
        csv_concat = "../results/sourmash/sketches/read_pig_nomag/concat/{metag}.gather.csv"
    conda: 
        "csvtk"
    shell:
        """
        csvtk concat {input.fmg_pig} {input.fmg_human} > {output.csv_concat}
        """

# get clean sigs for pig metaGs with host rm
rule sig_rm_host:
    input:
        sig = "/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        picklist = "../results/sourmash/sketches/read_pig_nomag/concat/{metag}.gather.csv",
    output:
        sig = "../results/sourmash/sketches/read_pig_nomag/hostrm/{metag}.zip",
        csv='../results/sourmash/con_removal/{metag}.csv'
    conda: 
        "branchwater"
    threads: 1
    shell:
        """ 
        sourmash gather {input.sig} {PIG_GENOME} {HUMAN_GENOME} \
        --picklist {input.picklist}:match_md5:md5 -o {output.csv} \
        -k {KSIZE} --scaled 1000 --output-unassigned {output.sig}
        """