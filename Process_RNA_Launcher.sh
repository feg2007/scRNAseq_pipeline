#!/usr/bin/env bash

#SBATCH --job-name=rna_launcher      
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=youremail@example.com  # Replace with a valid email address or use an argument
#SBATCH --partition=all          
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4000M
#SBATCH --time=5-00:00:00
#SBATCH --output=slurm_outputs/%x_%j.out
#SBATCH --error=slurm_outputs/%x_%j.out

while getopts ":m:p:c:r:j:" opt; do
  case $opt in
    m) META_PATH="$OPTARG"
    ;;
    p) PIPELINE_PATH="$OPTARG"
    ;;
    c) CLUSTER_CONFIG="$OPTARG"
    ;;
    r) REF_GENOME="$OPTARG"
    ;;
    j) JOBS="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Check if mandatory arguments are provided
if [ -z "$META_PATH" ] || [ -z "$PIPELINE_PATH" ] || [ -z "$CLUSTER_CONFIG" ] || [ -z "$REF_GENOME" ] || [ -z "$JOBS" ]; then
    echo "Usage: $0 -m <path_to_RNA_FASTQs> -p <path_to_pipeline_directory> -c <cluster_config_file> -r <path_to_ref_genome> -j <number_of_jobs>"
    exit 1
fi

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

# Echo variable paths to standard output
echo "Processing files in ${META_PATH}..."
echo "Using pipeline from ${PIPELINE_PATH}..."
echo "Submitting to cluster with configuration ${CLUSTER_CONFIG}..."

cd ${META_PATH}
> config.yaml
echo "path: ${META_PATH}" > config.yaml
echo "pipeline_path: ${PIPELINE_PATH}" >> config.yaml
echo "ref_genome: ${REF_GENOME}" >> config.yaml

# Note: each directory specified should have a sub-directory called 'fastq' containing the fastq files for the sample
snakemake -s ${PIPELINE_PATH}/RNA_pipeline_STAR.mk \
          --configfile ${META_PATH}/config.yaml \
          --nolock \
          --jobs ${JOBS} \
          --latency-wait 60 \
          --cluster-config ${CLUSTER_CONFIG} \
          --cluster "sbatch -J {cluster.job-name} -p {cluster.partition} -t {cluster.time} -c {cluster.cpus-per-task} --mem={cluster.mem} -o {cluster.output} -e {cluster.error} --mail-type={cluster.mail-type} --mail-user={cluster.mail-user}"
