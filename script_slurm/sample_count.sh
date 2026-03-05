#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=sample_count
#SBATCH --account=nn10039k
#SBATCH --time=04:00:00
#SBATCH --mem=50G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=8
#SBATCH --partition=normal
#########################################

# variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/SCOUNT
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/MERGED_3_FILTERED_MAC_10%_BED
NAME=MERGED_3_FILTERED_MAC_10%_BED.SCOUNT
##Activate module

module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

cd $dir

plink2 --bfile $BED --sample-counts --allow-extra-chr --out $NAME
