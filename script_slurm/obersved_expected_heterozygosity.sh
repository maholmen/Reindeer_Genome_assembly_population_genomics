#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=HETEROZYGOSITY
#SBATCH --account=nn10039k
#SBATCH --time=04:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=6
#SBATCH --partition=bigmem,normal
#########################################

#variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/MERGED_3_FILTERED_MAC.LD_PRUNED

#activate module
module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

echo "changing to $dir"

cd $dir/HET_LD_PRUNED

#plink --bfile $BED --allow-extra-chr --make-bed \
#    --geno 0.01 \
#    --out HET

for POP in FI VA FR RH IC LO; do
    plink --bfile $BED --allow-extra-chr \
        --keep /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/${POP}_subset.txt \
        --het --out ${POP}_HET

    awk '
    BEGIN { OFS="\t"; print "FID","IID","HO","HE" }
    NR > 1 { print $1, $2, 1 - ($3 / $5), 1 - ($4 / $5) }
    ' ${POP}_HET.het > ${POP}_heterozygosity.txt
done
