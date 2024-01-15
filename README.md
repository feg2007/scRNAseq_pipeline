# Single-Cell RNA-Seq Processing Pipeline for smart-RRBS data

A comprehensive pipeline for processing single-cell RNA-Seq data, generating TPM and raw counts matrices from RSEM results, and annotating them with gene symbols.

## Description

This pipeline is meant to be used with RNA-Seq raw data generated using the smart-RRBS protocol. It merges the fastq files for each cell within a sample, and then uses STAR and RSEM to align the reads to the reference genome and generate TPM and raw counts matrices for each sample.

## Initial Setup

It is recommended to use [`conda`]()/[`mamba`]() to install the necessary dependencies. The following commands will create a new environment and install the necessary packages:
```bash
mamba create -c r -c conda-forge -c bioconda -n snakemake_rna snakemake python rsem star r-data.table r-ggplot2 r-Seurat r-seuratobject=4.1.4 r-readr r-Matrix bioconductor-homo.sapiens r-gridExtra
```

After the environment is setup, activate it with the following command:
```bash
mamba activate snakemake_rna
```



**Note:** Currently there is a known bug with the `txdb.hsapiens.ucsc.hg19.knowngene` R package a dependency of the `Homo.sapiens` package. If an error occurs in installation related to this package please try the following instead:
```bash
mamba create -c r -c conda-forge -c bioconda -n snakemake_rna snakemake python rsem star r-data.table r-ggplot2 r-Seurat r-seuratobject=4.1.4 r-readr r-Matrix bioconductor-homo.sapiens r-gridExtra bioconductor-txdb.hsapiens.ucsc.hg19.knowngene=3.2.2=r43hdfd78af_15
```

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/GaitiLab/scRNAseq_pipeline.git
   cd scRNAseq_pipeline
   ```
2. Modify the SLURM scripts to ensure they contain the proper partitions and email addresses for your accounts, especially for `Run_RNA.sh`.
3. Ensure all `.sh` scripts can be execuded. (i.e. use the command `chmod +x <script_name>.sh`)
4. Modify the cluster.yaml file to ensure it is compatible with the HPC you are using for the run.
5. Run the master script, which will submit jobs for each sample. For more details see the [Parameters](#parameters-for-process_rna_launchersh) section below.
    ```bash
    ./Process_RNA_Launcher.sh -m path_to_scRNA_FASTQ_sample_dirs/ \
                            -p path_to_pipeline/ \
                            -c path_to_cluster_config/ \
                            -r path_to_ref_genome_files/
    ```
Ensure you've set up the appropriate directory structure as the scripts expect a specific layout.

## Workflow Overview
1. RSEM Analysis: Processes multiple RNA-Seq paired-end fastq files for each cell within a sample to produce `.RSEM.genes.results` files.
2. Matrix Generation: Reads the RSEM results to generate:
   - TPM matrix (with gene symbols as row names).
   - Raw counts matrix (with gene symbols as row names).
3. Generate QC plots: Generates QC plots for each sample using the TPM matrix. Another plot combining the QC plots for all samples is also generated.

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
1. `<sample_name>.tpm.counts file`: A matrix of TPM values with genes as rows and cells as columns.
2. `<sample_name>.rsem.counts file`: A matrix of raw counts with genes as rows and cells as columns.
3. `<sample_name>_metadata.csv`: A metadata file containing information about the cells in the sample. Contains the following columns: nCount_RNA, nFeature_RNA, percent_mito, percent_house, percent_ribo where the last three columns denote the percentage of mitochondrial, housekeeping, and ribosomal genes respectively.
4. `<sample_name>_violin_plot.pdf`: A violin plot showing the distribution of the nFeature_RNA, nCount_RNA, percent_ribo and percent_mito columns.

The root folder will also contain a `combined_metadata.csv` file which contains the metadata for all samples combined. It will also contain a `combined_violin_plot.pdf` file which contains the violin plots for all samples combined.

## Parameters for `Process_RNA_Launcher.sh`
When executing the `Process_RNA_Launcher.sh` script, it requires several parameters to function correctly:

### 1. `META_PATH` (m)
This is the path to the root directory containing all the samples. Each sample directory should have a sub-directory named fastq which contains the paired-end fastq files for multiple cells.

### 2. `PIPELINE_PATH` (p)
Description:
Path to the directory containing the Snakemake pipeline. This is where your Snakemake rules file (and potentially other related scripts) is located. This is most potentially, the directory you are running from (if you cloned the repository).

### 3. `CLUSTER_CONFIG` (c)
Path to the configuration file for cluster parameters. This config file is used to specify cluster resources for each Snakemake rule when submitting jobs. It should be in JSON or YAML format, defining resources for each rule, like CPUs, memory, etc. A sample file is provided but may need to be modified.

### 4. `REF_GENOME` (r)
Path to the reference genome to be used for the analysis. (*Note that this is the path to the prefix of the genome file. i.e. `<path>/<to>/human_hg38`) This needs to be generated using STAR or even through RSEM. See their respecitve documentation for more details ([STAR](https://github.com/alexdobin/STAR), [RSEM](https://deweylab.github.io/RSEM/rsem-prepare-reference.html)).

Once these parameters are correctly set, you can execute the master_RNA.sh script, and it will in turn utilize the `Run_RNA.sh` script for processing each sample. Remember to ensure that the SLURM scripts have the necessary permissions for execution (```chmod +x script_name.sh```).

## Contributing
If you find any bugs or would like to improve the pipeline, please create an issue or submit a pull request.