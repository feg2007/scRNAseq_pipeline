configfile: "config.yaml"

rule all:
    input:
        expand("{sample}_ME_L001_R1_001.fastq", sample=config['samples']),
        expand("{sample}_ME_L001_R2_001.fastq", sample=config['samples']),
        expand("{name}.tpm.counts", name=config["name"]),
        expand("{name}.rsem.counts", name=config["name"]),
        expand("{name}_metadata.csv", name=config["name"]),
        expand("{name}_violion_plot.pdf", name=config["name"]),
        "combined_metadata.csv",
        "combined_qc_plot.pdf"

rule merge_fastqs:
    input:
        "{sample}_L001_R1_001.fastq.gz",
        "{sample}_L001_R2_001.fastq.gz"
    output:
        r1_merged="{sample}_ME_L001_R1_001.fastq",
        r2_merged="{sample}_ME_L001_R2_001.fastq"
    log:
        "../logs/{sample}.merge.log"
    shell:
        "./merge_script.sh ./ ./ {wildcards.sample}"

rule RSEM:
    input:
        R1="{sample}_ME_L001_R1_001.fastq".format(sample=config['samples']),
        R2="{sample}_ME_L001_R2_001.fastq".format(sample=config['samples'])
    output:
        "{sample}.RSEM.genes.results"
    log: 
        "../logs/{sample}.rsem.log"
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
        "R/build_matrix_STAR_tpm.R"

rule generate_raw_counts_matrix:
    input:
        files=expand("{dataset}.RSEM.genes.results", dataset=config["samples"])
    output:
        matrix=expand("{name}.rsem.counts", name=config["name"])
    script:
        "R/build_matrix_STAR_counts.R"

rule RNA_QC:
    input:
        scRNA = "{name}.rsem.counts"
    output:
        metadata = "{name}_metadata.csv",
        violin_plot = "{name}_violion_plot.pdf"
    script:
        "R/generate_RNA_qc.R"

rule combine_qc_metadata:
    input:
        expand("{name}_metadata.csv", name=config["name"])
    output:
        combined_metadata = "combined_metadata.csv",
        combined_plot = "combined_qc_plot.pdf"
    script:
        "R/generate_combined_qc.R"