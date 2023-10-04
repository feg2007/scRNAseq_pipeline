# Single-Cell RNA-Seq Analysis Pipeline with Snakemake

A comprehensive pipeline for processing single-cell RNA-Seq data, generating TPM and raw counts matrices from RSEM results, and annotating them with gene symbols.

## Description

This pipeline integrates Snakemake with a set of scripts and workflows for processing single-cell RNA-Seq data. It reads RSEM results from multiple paired-end fastq files for each cell within a sample, extracts TPM values and raw counts, and creates matrices annotated with gene symbols from the ENSEMBL database. The pipeline is designed for efficiency and speed, utilizing the `data.table` R package for fast data I/O.

## Requirements

- R (> 4.0.0)
  - Packages: [`Homo.sapiens`](https://www.bioconductor.org/packages/Homo.sapiens/), [`data.table`](https://cran.r-project.org/package=data.table)
- [Snakemake](https://snakemake.readthedocs.io/en/stable/) (>= 7.3.8)
- [STAR](https://github.com/alexdobin/STAR) (>= 2.7.9a)
- [RSEM](https://deweylab.github.io/RSEM/) (>= 1.3.0)
- Python (>= 3.6)

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/GaitiLab/scRNAseq_pipeline.git
   cd scRNAseq_pipeline
   ```
2. Modify the SLURM scripts to ensure they contain the proper partitions and email addresses for your accounts, especially for `run_RNA.sh`.
3. Modify the cluster.yaml file to ensure it is compatible with the HPC you are using for the run.
3. Run the master script, which will submit jobs for each sample. For more details see the [Parameters](#parameters-for-processrnalaunchersh) section below.
    ```bash
    ./ProcessRNALauncher.sh -m path_to_scRNA_FASTQ_sample_dirs/ \
                            -p path_to_pipeline/ \
                            -c path_to_cluster_config/ \
                            -r path_to_ref_genome/
    ```
Ensure you've set up the appropriate directory structure as the scripts expect a specific layout.

## Workflow Overview
1. RSEM Analysis: Processes multiple RNA-Seq paired-end fastq files for each cell within a sample to produce `.RSEM.genes.results` files.
2. Matrix Generation: Reads the RSEM results to generate:
   - TPM matrix (with gene symbols as row names).
   - Raw counts matrix (with gene symbols as row names).

## Input Directory Structure
The expected directory structure for input files is:
```
path_to_scRNA_FASTQ_sample_dirs/
│
├── sample1/
│   └── fastq/
│       ├── cell1_R1_001.fastq
│       ├── cell1_R2_001.fastq
│       ├── cell2_R1_001.fastq
│       ├── cell2_R2_001.fastq
│       ... (and so on for multiple cells within sample1)
│
├── sample2/
│   └── fastq/
│       ├── cell1_R1_001.fastq
│       ├── cell1_R2_001.fastq
│       ... (and so on for multiple cells within sample2)
│
... (and so on for other samples)
```

## Outputs
For each sample, you will obtain:
1. `.tpm.counts file`: A matrix of TPM values with genes as rows and cells as columns.
2. `.rsem.counts file`: A matrix of raw counts with genes as rows and cells as columns.

## Parameters for `ProcessRNALauncher.sh`
When executing the `ProcessRNALauncher.sh` script, it requires several parameters to function correctly:

### 1. `META_PATH` (m)
This is the path to the root directory containing all the samples. Each sample directory should have a sub-directory named fastq which contains the paired-end fastq files for multiple cells.

### 2. `PIPELINE_PATH` (p)
Description:
Path to the directory containing the Snakemake pipeline. This is where your Snakemake rules file (and potentially other related scripts) is located. This is most potentially, the directory you are running from (if you cloned the repository).

### 3. `CLUSTER_CONFIG` (c)
Path to the configuration file for cluster parameters. This config file is used to specify cluster resources for each Snakemake rule when submitting jobs. It should be in JSON or YAML format, defining resources for each rule, like CPUs, memory, etc. A sample file is provided but may need to be modified.

### 4. `REF_GENOME` (r)
Path to the reference genome to be used for the analysis. (*Note that this is the path to the directory and not the genome fasta itself.*) This needs to be generated using STAR or even through RSEM. See their respecitve documentation for more details ([STAR](https://github.com/alexdobin/STAR), [RSEM](https://deweylab.github.io/RSEM/rsem-prepare-reference.html)).

Once these parameters are correctly set, you can execute the master_RNA.sh script, and it will in turn utilize the run_RNA.sh script for processing each sample. Remember to ensure that the SLURM scripts have the necessary permissions for execution (```chmod +x script_name.sh```).

## Contributing
If you find any bugs or would like to improve the pipeline, please create an issue or submit a pull request.