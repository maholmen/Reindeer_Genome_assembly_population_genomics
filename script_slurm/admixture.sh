#!/bin/bash
############SLURM arguments#############

#SBATCH --job-name=admixture_rep
#SBATCH --account=nn10039k
#SBATCH --time=15:00:00
#SBATCH --mem=200G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=16
#SBATCH --partition=normal,bigmem
#########################################

# variables
K=$1 (1-6)
rep=$SLURM_ARRAY_TASK_ID (1-10 for each K)

dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/ADMIXTURE/replicates
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/ADMIXTURE/replicates/input_admixture.bed

cd $dir

module load ADMIXTURE/1.3.0
admixture --seed=$SLURM_ARRAY_TASK_ID --cv=10 -j8 $BED $K > log.${rep}.${K}.out
