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

while getopts ":s:p:c:r:" opt; do
  case $opt in
    s) MY_PATH=$(readlink -f "$OPTARG")
    ;;
    p) MY_PIPELINE=$(readlink -f "$OPTARG")
    ;;
    c) MY_CLUSTER_CONFIG=$(readlink -f "$OPTARG")
    ;;
    r) MY_REF_GENOME=$(readlink -f "$OPTARG")
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Check if mandatory arguments are provided
if [ -z "$MY_PATH" ] || [ -z "$MY_PIPELINE" ] || [ -z "$MY_CLUSTER_CONFIG" ] || [ -z "$MY_REF_GENOME" ]; then
    echo "Usage: $0 -s <sample_directory> -p <path_to_pipeline_directory> -c <cluster_config_file> -r <path_to_ref_genome>"
    exit 1
fi

# Echo variable paths to standard output
echo "Processing files in ${MY_PATH}..."
echo "Using pipeline from ${MY_PIPELINE}..."
echo "Submitting to cluster with configuration ${MY_CLUSTER_CONFIG}..."

name="${MY_PATH##*/}"
echo "Processing sample ${name}..."

# Check if the directory exists
if [[ -d "${MY_PATH}/fastq" ]]; then
    cd ${MY_PATH}/fastq
else
    echo "${MY_PATH}/fastq does not exist. Exiting."
    exit 1
fi

# Clear config file or create a new unique one
> config.yaml

module load STAR/2.7.9a
module load R/4.2.1
module load python3
module load snakemake/7.3.8
module load perl/5.30.0
module load rsem/1.3.0

# Determine the directory containing the STAR executable
STAR_DIR=$(dirname $(which STAR))

# Determine the path to the RSEM executable
RSEM_EXEC=$(which rsem-calculate-expression)

# Check if fastq.gz files exist, otherwise assume .fastq
if ls ${MY_PATH}/fastq/*R1_001.fastq.gz 1> /dev/null 2>&1; then
    EXTENSION=".fastq.gz"
else
    EXTENSION=".fastq"
fi

# Now, use the STAR_DIR variable when creating the config.yaml file
echo "path: ${MY_PATH}/fastq" > config.yaml
echo "name: ${name}" >> config.yaml
echo "star_path: ${STAR_DIR}" >> config.yaml  # Using the determined STAR directory path
echo "RSEM_path: ${RSEM_EXEC}" >> config.yaml  # Using the direct path to the RSEM executable
echo "ref_genome: ${MY_REF_GENOME}" >> config.yaml
echo "fastq_extension: ${EXTENSION}" >> config.yaml
echo "samples:" >> config.yaml

for file in *R1_001.fastq *R1_001.fastq.gz; do
    if [[ $file == *_R1_001.fastq ]]; then
        sample=`basename $file _R1_001.fastq`
    elif [[ $file == *_R1_001.fastq.gz ]]; then
        sample=`basename $file _R1_001.fastq.gz`
    fi
    echo "- ${sample}" >> config.yaml
done

# Check if logs directory exists
if [[ ! -d "../logs" ]]; then
    mkdir ../logs
fi

snakemake -s ${MY_PIPELINE}/RNA_pipeline_STAR.mk \
          --configfile ${MY_PATH}/fastq/config.yaml \
          --cluster-config ${MY_CLUSTER_CONFIG} \
          --nolock \
          --cluster "sbatch -J {cluster.job-name} -p {cluster.partition} -t {cluster.time} -c {cluster.cpus-per-task} --mem={cluster.mem} -o {cluster.output} -e {cluster.error} --mail-type={cluster.mail-type} --mail-user={cluster.mail-user}" \
          --jobs 1000
