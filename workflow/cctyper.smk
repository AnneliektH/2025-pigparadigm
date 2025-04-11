# all genomes
FASTA, = glob_wildcards('/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/all_genomes/{ident}.fasta')

rule all:
    input:
        expand("../results/crispr/cctyper/check/{ident}.done", ident=FASTA),

rule ctyper:
    input:
        fasta = '/group/ctbrowngrp2/scratch/annie/2023-swine-sra/results/MAGs/genomes/all_genomes/{ident}.fasta', 
    output:
        txt='../results/crispr/cctyper/check/{ident}.done',
    conda: 
        "cctyper"
    threads: 4
    shell:
        """
        cctyper {input.fasta} ../results/crispr/cctyper/{wildcards.ident} \
        -t {threads} && touch {output.txt}
        """


