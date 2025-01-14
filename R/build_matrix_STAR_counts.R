# build_matrix_STAR_counts.R
# Description: Processes RSEM gene results to create a raw counts matrix.
# Input: Directory path with .RSEM.genes.results files (from Snakemake).
# Output: Raw counts matrix with gene SYMBOLs as row names.

log <- file(snakemake@log[[1]], open="wt")
sink(log, type = "output")
sink(log, type = "message")

# Capture snakemake inputs and outputs
input_path <- snakemake@config[["path"]]
output_file <- snakemake@output[["matrix"]]

input_path <- paste0(input_path, "/", dirname(output_file), "/RSEM/")
print(paste0("Input path: ", input_path))
print(paste0("Output file: ", output_file))

# Check for required libraries
required_packages <- c("EnsDb.Hsapiens.v86", "data.table")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) stop(paste("Missing packages:", paste(new_packages, collapse=", ")))

library(EnsDb.Hsapiens.v86)
library(data.table)

# List and read RSEM files
expr_files <- list.files(path = input_path, pattern = "*.RSEM.genes.results$", full.names = TRUE)
if(length(expr_files) == 0) stop("No RSEM files found.")
expr_matrices <- lapply(expr_files, function(file){
  dt <- fread(file, data.table = FALSE)  # Read as data.frame
  if(!"expected_count" %in% colnames(dt)) stop(paste("expected_count column missing in", file))
  setNames(dt[,"expected_count"], dt[,1])  # Set rownames using the first column (gene IDs)
})
expr_matrix <- do.call(cbind, expr_matrices)
colnames(expr_matrix) <- gsub(".RSEM.genes.results$", "", basename(expr_files))

# Annotate genes
info <- select(EnsDb.Hsapiens.v86, keys = rownames(expr_matrix), columns = c("SYMBOL"), keytype = "TXID")

# Remove duplicate and NA SYMBOLs
unique_symbols <- !duplicated(info$SYMBOL[match(rownames(expr_matrix), info$ENSEMBL)])
non_na_symbols <- !is.na(info$SYMBOL[match(rownames(expr_matrix), info$ENSEMBL)])
expr_matrix <- expr_matrix[unique_symbols & non_na_symbols, ]

# Update row names with SYMBOLs
rownames(expr_matrix) <- info$SYMBOL[match(rownames(expr_matrix), info$ENSEMBL)]

# Write the matrix using fwrite
fwrite(as.data.table(expr_matrix, keep.rownames = "GeneID"), file = output_file, sep = "\t", quote = FALSE)