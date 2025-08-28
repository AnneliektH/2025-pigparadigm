GENOMES, = glob_wildcards('/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes/{ident}.fasta')

GTDB = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.k31.rocksdb'
GTDB_SQLDB = '/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.lineages.csv'


rule all:
    input:
        expand('/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_tax/{ident}.tax.csv', ident=GENOMES),


rule sketch:
    input:
        fasta='/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/all_genomes/{ident}.fasta',
    output:
        sig='/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sketches/{ident}.zip',
    shell: """
        sourmash sketch dna -p k=31 {input.fasta} --name {wildcards.ident} -o {output.sig}
    """

rule do_gather:
    input:
        sig='/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sketches/{ident}.zip',
    output:
        csv='/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_tax/{ident}.gather.csv',
        txt = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_tax/{ident}.gather.txt',
        check = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_check/{ident}.gather.check',
    shell: """
        sourmash gather {input.sig} {GTDB} -o {output.csv} --create-empty-results -k 31 \
        --threshold-bp=0 > {output.txt} && touch {output.check}
    """

rule tax_gather:
    input:
        csv='/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_tax/{ident}.gather.csv',
        check = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_check/{ident}.gather.check',
        taxdb=GTDB_SQLDB,
    output:
        taxout = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/MAGs/sourmash_tax/{ident}.tax.csv',
    shell: """
        sourmash tax genome -g {input.csv} -t {input.taxdb} > {output}
    """