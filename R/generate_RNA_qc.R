# RNASeq_Seurat_QC.R

# Loading necessary libraries
# libraries_to_load <- c("Seurat", "Matrix", "ggplot2", "readr")
# lapply(libraries_to_load, library, character.only = TRUE)

library(readr)
library(ggplot2)
library(Matrix)
library(Seurat)

# Function to read genes from a file and return rownames
read_gene_file <- function(filename) {
  genes <- read.table(filename)
  row.names(genes) <- genes[,1]
  return(row.names(genes))
}

# Function to compute percentage of gene expression and add to metadata
add_percent_metadata <- function(object, gene_set, col_name) {
  percent <- colSums(object@assays$RNA@counts[gene_set, ]) / colSums(object@assays$RNA@counts)
  percent <- percent * 100
  AddMetaData(object, metadata = percent, col.name = col_name)
}

calculate_percent_ribo <- function(seurat_object, gene_pattern = "^RP[SL][[:digit:]]") {
    ribo_genes <- grep(pattern = gene_pattern, x = rownames(x = seurat_object@assays$RNA@data), value = TRUE)
    percent_ribo <- Matrix::colSums(seurat_object@assays$RNA@counts[ribo_genes, ]) / Matrix::colSums(seurat_object@assays$RNA@counts) * 100
    seurat_object <- AddMetaData(object = seurat_object, metadata = percent_ribo, col.name = "percent_ribo")
    return(seurat_object)
}

# Input arguments
args <- commandArgs(TRUE)
scRNA_file_path <- snakemake@input[["scRNA"]]
output_metadata <- snakemake@output[["metadata"]]
output_violin_plot <- snakemake@output[["violin_plot"]]

# Reading genes
mito_genes <- read_gene_file(paste0(snakemake@config[["pipeline_path"]], "/Data/Human_Mito_Genes.txt"))
house_genes <- read_gene_file(paste0(snakemake@config[["pipeline_path"]], "/Data/HSIAO_housekeeping_genes.txt"))

# Loading scRNA data
scRNA <- read.table(scRNA_file_path, sep = "\t", header = TRUE, row.names = 1)
scRNA <- as.data.frame(scRNA)

# Initializing Seurat object
seurat_obj <- CreateSeuratObject(scRNA, project = "test")

# Add metadata to seurat object
seurat_obj <- add_percent_metadata(seurat_obj, mito_genes, "percent_mito")
seurat_obj <- add_percent_metadata(seurat_obj, house_genes, "percent_house")
seurat_obj <- calculate_percent_ribo(seurat_obj)

# Visualization and save the plot
plot <- VlnPlot(object = seurat_obj, features = c("nFeature_RNA", "nCount_RNA", "percent_ribo", "percent_mito"))
ggsave(filename = output_violin_plot, plot = plot, width = 10, height = 8)

# Saving Output
write.csv(seurat_obj@meta.data, file = output_metadata)