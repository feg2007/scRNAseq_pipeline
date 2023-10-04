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

# Get full paths
MY_PATH=$(readlink -f ${1})
MY_PIPELINE=$(readlink -f ${2})

# Echo variable paths to standard output
echo "Processing files in ${MY_PATH}..."
echo "Using pipeline from ${MY_PIPELINE}..."

MY_CLUSTER_CONFIG=$(readlink -f ${3})
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

echo "path: ${MY_PATH}/fastq" > config.yaml
echo "name: ${name}" >> config.yaml
echo "samples:" >> config.yaml

for file in *R1_001.fastq; do
    sample=`basename $file _R1_001.fastq`
    echo "- ${sample}" >> config.yaml
done

module load STAR/2.7.9a
module load R/4.2.1
module load python3
module load snakemake/7.3.8
module load perl/5.30.0
module load rsem/1.3.0

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
