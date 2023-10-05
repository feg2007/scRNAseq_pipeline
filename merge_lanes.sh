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

    echo "Merging R2"
    zcat ${MULTI_LANE_PATH}/${i}_L00*_R2_001.fastq.gz > ${SINGLE_LANE_PATH}/${i}_ME_L001_R2_001.fastq
}

export -f merge_files

# For each sample provided by Snakemake, call the merge_files function
for sample in "$@"; do
    merge_files "$sample"
done