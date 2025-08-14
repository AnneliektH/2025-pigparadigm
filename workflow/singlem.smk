import pandas as pd
# set list of samples
METAG = pd.read_csv("../resources/least_explained_metag.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/singlem/{sample}_singlem.json', sample=METAG,),


#Download SRA files
rule download_sra:
    output:
        sra = temporary("../results/sra/{sample}")
    log:
        "../results/logs/prefetch.{sample}.log"
    conda:
        "sra"
    shell:
        """
        mkdir -p ../results/sra/
        if [ ! -f "../results/check/{wildcards.sample}_fasterqdump.check" ] && [ ! -f "{output.sra}" ]; then
            aws s3 cp --quiet --no-sign-request s3://sra-pub-run-odp/sra/{wildcards.sample}/{wildcards.sample} {output.sra}
        fi &> {log}
        """
   
     
# Download the whole thing, including smaller reads, as atlas will quality trim
rule fasterq_dump:
    input:
        sra_file = "../results/sra/{sample}"
    output:
        check = "../results/check/{sample}_fasterqdump.check"
    log:
        "../results/logs/fasterq_dump.{sample}.log"
    conda: 
        "sra"
    benchmark: "../results/logs/fasterq_dump.{sample}.benchmark"
    threads: 12
    shell:
        """
        fasterq-dump {input.sra_file} --threads {threads} \
        -O ../results/reads/fasterq/{wildcards.sample} --skip-technical \
        --bufsize 1000MB --curcache 10000MB && \
        pigz -f -p {threads} ../results/reads/fasterq/{wildcards.sample}/*.fastq && \
        touch {output.check}
        """


rule singleM:
    input:
        sra = "../results/check/{sample}_fasterqdump.check"
    output:
        profile = "../results/singlem/{sample}_singlem.tsv"
    conda: 
        "singlem"
    params: 
        in_folder = "../results/reads/fasterq/"
    threads: 12
    shell:
        """
        singlem pipe -1 {params.in_folder}/{wildcards.sample}/{wildcards.sample}_1.fastq.gz \
        -2 {params.in_folder}/{wildcards.sample}/{wildcards.sample}_2.fastq.gz \
        -p {output.profile} --threads {threads} 
        """


rule taxburst:
    input:
        profile = "../results/singlem/{sample}_singlem.tsv"
    output:
        json = "../results/singlem/{sample}_singlem.json"
    conda: 
        "taxburst"
    threads: 1
    shell:
        """
        taxburst -F SingleM {input.profile} --save-json {output.json}
        """