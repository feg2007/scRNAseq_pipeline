# generate_combined_qc.R

library(readr)
library(ggplot2)
library(gridExtra)

# Read input arguments
args <- commandArgs(TRUE)
input_files <- snakemake@input
output_csv <- snakemake@output[["combined_metadata"]]
output_plot <- snakemake@output[["combined_plot"]]

# Define a function to read data and assign sample attribute
read_data <- function(filename) {
  df <- read_csv(filename)
  sample_name <- tools::file_path_sans_ext(basename(filename))  # Extract sample name from filename
  sample_name <- sub("_metadata$", "", sample_name)  # Remove '_metadata' suffix
  df$Sample <- sample_name
  return(df)
}

# Read in all data files
allQC <- do.call(rbind, lapply(input_files, read_data))

# Apply filters
allQC <- allQC[allQC$nFeature_RNA > 500 & 
               allQC$percent_mito < 25 & 
               allQC$percent_ribo < 25 & 
               allQC$nCount_RNA < quantile(allQC$nCount_RNA, 0.999),]

# Order the factor levels of Sample based on sample names
allQC$Sample <- factor(allQC$Sample, levels = unique(allQC$Sample), ordered = TRUE)

# Function to create visualizations
create_plot <- function(y_axis, y_label, y_limit = NULL, y_intercept = NULL) {
  plot <- ggplot(data = allQC, aes(x=Sample, y = y_axis)) +
          geom_boxplot(notch = F, outlier.shape = NA) +
          geom_jitter(alpha = 0.5, width=0.1, cex=1) +
          labs(y = y_label, x = "Sample") +
          theme_classic(base_size = 11) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  if (!is.null(y_limit)) {
    plot <- plot + ylim(y_limit)
  }
  
  if (!is.null(y_intercept)) {
    plot <- plot + geom_hline(yintercept = y_intercept, linetype="dashed", color = "red")
  }
  
  return(plot)
}

plot_nFeature_RNA <- create_plot(allQC$nFeature_RNA, "no. of genes", c(-5, 15000), 500)
plot_nCount_RNA <- create_plot(allQC$nCount_RNA, "no. of reads")
plot_percent_mito <- create_plot(allQC$percent_mito, "Percentage mithocondrial genes", c(-5, 105), 25)
plot_percent_ribo <- create_plot(allQC$percent_ribo, "Percentage ribosomal genes", c(-5, 105), 25)

combined_plot <- grid.arrange(plot_nFeature_RNA, plot_nCount_RNA, plot_percent_mito, plot_percent_ribo)

# Save the combined plot
ggsave(filename = output_plot, plot = combined_plot, width = 20, height = 20)

# Save the aggregated data
write.csv(allQC, file = output_csv)