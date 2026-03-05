#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=ROH
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=16
#SBATCH --partition=bigmem,normal
#########################################



#variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2
BED=MERGED_3_FILTERED_MAC_10%_BED

#activate module
module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

echo "changing to $dir"

cd $dir/ROH

for lenght in 1 100 500 1000 2000 4000 8000; do

    plink --bfile $dir/$BED --allow-extra-chr --homozyg-window-het 1 --homozyg-kb $lenght --homozyg-snp 50 --homozyg-window-snp 50 --homozyg-gap 1000 \
    --homozyg-density 50 --homozyg-window-threshold 0.05 \
    --make-bed --out $lenght.NORWEGIAN_and_ICELAND

done
