import os
import glob

# Load configuration
configfile: "config.yaml"

sample_dirs = [d for d in next(os.walk('.'))[1] if d != "logs" and not d.startswith('.')]

# Function to get cells for each sample
def get_cells(sample):
    fastq_files = glob.glob(os.path.join(sample, "fastq", "*.fastq.gz"))
    cells = set(os.path.basename(f).split("_L00")[0] for f in fastq_files)
    return list(cells)

# Collect all expected output files for the `all` rule
output_files = []
for sample in sample_dirs:
    for cell in get_cells(sample):
        for read in [1, 2]:
            output_files.append(f"{sample}/merged/{cell}_ME_L001_R{read}_001.fastq")

# Collect all expected RSEM output files for the `all` rule
rsem_output_files = []
for sample in sample_dirs:
    cells = get_cells(sample)
    for cell in cells:
        rsem_output_files.append(f"{sample}/RSEM/{cell}.RSEM.genes.results")

def get_rsem_results_for_sample(sample):
    cells = get_cells(sample)
    return expand("{sample}/RSEM/{cell}.RSEM.genes.results", sample=sample, cell=cells)

tpm_output_files = []
count_output_files = []
qc_files = []
for sample in sample_dirs:
    if sample == "logs":
        continue
    tpm_output_files.append(f"{sample}/{sample}.tpm.counts")
    count_output_files.append(f"{sample}/{sample}.rsem.counts")
    qc_files.append(f"{sample}/{sample}_metadata.csv")
    qc_files.append(f"{sample}/{sample}_violion_plot.pdf")

rule all:
    input:
        output_files,
        rsem_output_files,
        tpm_output_files,
        count_output_files,
        qc_files,
        "combined_metadata.csv",
        "combined_qc_plot.pdf"

rule merge_lanes:
    input:
        r1=lambda wildcards: glob.glob(f"{wildcards.sample}/fastq/{wildcards.cell}_L00*_R1_001.fastq.gz"),
        r2=lambda wildcards: glob.glob(f"{wildcards.sample}/fastq/{wildcards.cell}_L00*_R2_001.fastq.gz")
    output:
        r1="{sample}/merged/{cell}_ME_L001_R1_001.fastq",
        r2="{sample}/merged/{cell}_ME_L001_R2_001.fastq"
    log:
        "logs/merge_lanes_{sample}_{cell}.log"
    shell:
        """
        {config[pipeline_path]}/merge_lanes.sh {output.r1} {input.r1}
        {config[pipeline_path]}/merge_lanes.sh {output.r2} {input.r2}
        """

rule RSEM:
    input:
        r1="{sample}/merged/{cell}_ME_L001_R1_001.fastq",
        r2="{sample}/merged/{cell}_ME_L001_R2_001.fastq"
    output:
        "{sample}/RSEM/{cell}.RSEM.genes.results"
    log: 
        "logs/{sample}_{cell}.rsem.log"
    threads: 8
    shell:
        """
        output_prefix=`python -c "print('{output}'.replace('.genes.results', ''))"`
        rsem-calculate-expression --paired-end --star --star-path $(dirname $(which STAR)) \
            -p {threads} {input.r1} {input.r2} \
            {config[ref_genome]} $output_prefix \
            > {log} 2>&1
        """

rule generate_matrix:
    input:
        lambda wildcards: get_rsem_results_for_sample(wildcards.sample)
    output:
        matrix="{sample}/{sample}.tpm.counts"
    log:
        "logs/{sample}.generate_matrix.log"
    script:
        "R/build_matrix_STAR_tpm.R"

rule generate_raw_counts_matrix:
    input:
        lambda wildcards: get_rsem_results_for_sample(wildcards.sample)
    output:
        matrix="{sample}/{sample}.rsem.counts"
    log:
        "logs/{sample}.generate_raw_counts_matrix.log"
    script:
        "R/build_matrix_STAR_counts.R"

rule RNA_QC:
    input:
        scRNA = lambda wildcards: f"{wildcards.sample}/{wildcards.sample}.rsem.counts"
    output:
        metadata = "{sample}/{sample}_metadata.csv",
        violin_plot = "{sample}/{sample}_violion_plot.pdf"
    log:
        "logs/{sample}.RNA_QC.log"
    script:
        "R/generate_RNA_qc.R"

rule combine_qc_metadata:
    input:
        expand("{sample}/{sample}_metadata.csv", sample=sample_dirs)
    output:
        combined_metadata = "combined_metadata.csv",
        combined_plot = "combined_qc_plot.pdf"
    log:
        "logs/combine_qc_metadata.log"
    script:
        "R/generate_combined_qc.R"