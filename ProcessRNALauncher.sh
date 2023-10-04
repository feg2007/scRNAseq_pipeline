#!/usr/bin/env bash

while getopts ":m:p:c:r:" opt; do
  case $opt in
    m) META_PATH="$OPTARG"
    ;;
    p) PIPELINE_PATH="$OPTARG"
    ;;
    c) CLUSTER_CONFIG="$OPTARG"
    ;;
    r) REF_GENOME="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Check if mandatory arguments are provided
if [ -z "$META_PATH" ] || [ -z "$PIPELINE_PATH" ] || [ -z "$CLUSTER_CONFIG" ] || [ -z "$REF_GENOME" ]; then
    echo "Usage: $0 -m <path_to_RNA_FASTQs> -p <path_to_pipeline_directory> -c <cluster_config_file> -r <path_to_ref_genome>"
    exit 1
fi

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
        sbatch "${RNA_SCRIPT}" "${directory}" "${PIPELINE_PATH}" "${CLUSTER_CONFIG}" "${REF_GENOME}"
    else
        echo "Warning: No 'fastq' sub-directory found in ${directory}. Skipping..."
    fi
done