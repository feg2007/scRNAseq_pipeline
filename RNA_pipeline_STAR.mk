configfile: "config.yaml"

rule all:
    input:
        expand("{name}.tpm.counts", name=config["name"]),
        expand("{name}.rsem.counts", name=config["name"])

rule RSEM:
    input:
        R1="{sample}_R1_001.fastq",
        R2="{sample}_R2_001.fastq"
    output:
        "{sample}.RSEM.genes.results"
    log: 
        "logs/{sample}.rsem.log"
    threads: 2
    shell:
        """
        {config[RSEM_path]} --paired-end --star --star-path {config[star_path]} \
            -p {threads} {config[path]}/{input.R1} {config[path]}/{input.R2} \
            {config[ref_genome]} {config[path]}/{wildcards.sample}.RSEM \
            > {log} 2>&1
        """

rule generate_matrix:
    input:
        file=expand("{dataset}.RSEM.genes.results", dataset=config["samples"])
    output:
        matrix=expand("{name}.tpm.counts", name=config["name"])
    script:
        "build_matrix_STAR_tpm.R"
    doc:
        "Generates TPM counts matrix from RSEM results."

rule generate_raw_counts_matrix:
    input:
        files=expand("{dataset}.RSEM.genes.results", dataset=config["samples"])
    output:
        matrix=expand("{name}.rsem.counts", name=config["name"])
    script:
        "build_matrix_STAR_counts.R"
    doc:
        "Generates raw counts matrix from RSEM results."
