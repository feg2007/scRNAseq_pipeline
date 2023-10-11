#!/bin/bash

MULTI_LANE_PATH=$1
SINGLE_LANE_PATH=$2

shift 2

# Function to perform the merge operation
merge_files() {
    i=$1
    echo "Processing file $i"

    echo "Merging R1"
    zcat ${MULTI_LANE_PATH}/${i}_L00*_R1_001.fastq.gz > ${SINGLE_LANE_PATH}/${i}_ME_L001_R1_001.fastq
    echo "Output file: ${SINGLE_LANE_PATH}/${i}_ME_L001_R1_001.fastq"
    echo "Checking if output file exists..."
    if [[ ! -f "${SINGLE_LANE_PATH}/${i}_ME_L001_R1_001.fastq" ]]; then
        echo "Error: ${SINGLE_LANE_PATH}/${i}_ME_L001_R1_001.fastq does not exist!"
        exit 1
    fi

    echo "Merging R2"
    zcat ${MULTI_LANE_PATH}/${i}_L00*_R2_001.fastq.gz > ${SINGLE_LANE_PATH}/${i}_ME_L001_R2_001.fastq
    echo "Output file: ${SINGLE_LANE_PATH}/${i}_ME_L001_R2_001.fastq"
    echo "Checking if output file exists..."
    if [[ ! -f "${SINGLE_LANE_PATH}/${i}_ME_L001_R2_001.fastq" ]]; then
        echo "Error: ${SINGLE_LANE_PATH}/${i}_ME_L001_R2_001.fastq does not exist!"
        exit 1
    fi
}

export -f merge_files

# For each sample provided by Snakemake, call the merge_files function
for sample in "$@"; do
    merge_files "$sample"
done