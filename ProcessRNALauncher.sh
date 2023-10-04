#!/usr/bin/env bash

# Check if the right number of arguments are provided
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <path_to_RNA_FASTQs> <path_to_pipeline_directory> <cluster_config_file>"
    exit 1
fi

META_PATH="$1"
PIPELINE_PATH="$2"
CLUSTER_CONFIG="$3"

# Reference to run_RNA.sh script
RNA_SCRIPT="run_RNA.sh"

# Check if META_PATH and PIPELINE_PATH exist and are directories
for directory in "$META_PATH" "$PIPELINE_PATH"; do
    if [[ ! -d "$directory" ]]; then
        echo "Error: '${directory}' is not a valid directory!"
        exit 2
    fi
done

# Check if CLUSTER_CONFIG is a valid file
if [[ ! -f "$CLUSTER_CONFIG" ]]; then
    echo "Error: '${CLUSTER_CONFIG}' is not a valid file!"
    exit 3
fi

# Note: each directory specified should have a sub-directory called 'fastq' containing the fastq files for the sample
for directory in "${META_PATH}"/*; do
    if [[ -d "${directory}/fastq" ]]; then
        echo "Submitting job for directory: ${directory}"
        sbatch "${RNA_SCRIPT}" "${directory}" "${PIPELINE_PATH}" "${CLUSTER_CONFIG}"
    else
        echo "Warning: No 'fastq' sub-directory found in ${directory}. Skipping..."
    fi
done