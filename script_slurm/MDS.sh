#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=genetic_distance_MDS
#SBATCH --account=nn10039k
#SBATCH --time=04:00:00
#SBATCH --mem=50G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=4
#SBATCH --partition=normal
#########################################

# variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/MDS
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/MERGED_3_FILTERED_MAC.LD_PRUNED
NAME=MDS_plot
##Activate module

module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

cd $dir

plink --bfile $BED --genome --allow-extra-chr --out $NAME
plink --bfile $BED --allow-extra-chr --read-genome $NAME.genome --cluster --mds-plot 2 --out $NAME

#modify output for downstream analysis
sed 's/\$//' $NAME.mds | awk '{$1=$1; OFS="\t"; print}' > $NAME.mds.mod
