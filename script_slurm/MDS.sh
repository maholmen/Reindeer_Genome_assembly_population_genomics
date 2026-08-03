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
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_JUNE_2026/MDS
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_JUNE_2026/MERGED_3_FILTERED_MAC.LD_PRUNED
NAME=MDS
##Activate module

module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

cd $dir

plink --bfile $BED --genome --allow-extra-chr --out $NAME.INCLUDING_IC

plink --bfile $BED --allow-extra-chr --read-genome $NAME.INCLUDING_IC.genome --cluster --mds-plot 2 --out $NAME.INCLUDING_IC

#modify output for downstream analysis
sed 's/\$//' $NAME.INCLUDING_IC.mds | awk '{$1=$1; OFS="\t"; print}' > $NAME.INCLUDING_IC.mds.mod


plink --bfile $BED --genome --allow-extra-chr --remove /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/IC_subset.txt --out $NAME.WITHOUT_IC
plink --bfile $BED --allow-extra-chr --read-genome $NAME.WITHOUT_IC.genome --remove /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/IC_subset.txt --cluster --mds-plot 2 --out $NAME.WITHOUT_IC

#modify output for downstream analysis
sed 's/\$//' $NAME.WITHOUT_IC.mds | awk '{$1=$1; OFS="\t"; print}' > $NAME.WITHOUT_IC.mds.mod
