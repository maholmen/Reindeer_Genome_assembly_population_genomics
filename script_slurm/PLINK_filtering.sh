#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=Filtering_PLINK
#SBATCH --account=nn10039k
#SBATCH --time=04:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=4
#SBATCH --partition=normal
#########################################

# variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2
VCF=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/VCF/MERGED_3_FILTERED_MAC_10%.vcf.gz

# Activate module
module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

# Filtering for Segregating variants and heterozygot per individual
cd $dir

#change to bed file - this file will be use for scount and segregating variants
plink --vcf $VCF --allow-extra-chr --make-bed \
  --double-id \
  --set-missing-var-ids @:# \
  --vcf-half-call missing \
  --not-chr chromosome_X_OX460343.1_557,chromosome_Y_OX460344.1_557 \
  --out MERGED_3_FILTERED_MAC_10%_BED


# Filtering for ROHs, HET (and later MDS and FST)
plink --bfile MERGED_3_FILTERED_MAC_10%_BED --allow-extra-chr --make-bed \
  --mind 0.1 \
  --hwe 1e-5 \
  --snps-only \
  --not-chr chromosome_X_OX460343.1_557,chromosome_Y_OX460344.1_557 \
  --out MERGED_3_FILTERED_MAC.PLINK_FILTERED

# Filtering for MDS and FST
plink --bfile MERGED_3_FILTERED_MAC.PLINK_FILTERED \
    --allow-extra-chr --indep-pairwise 50 5 0.5

plink --bfile MERGED_3_FILTERED_MAC.PLINK_FILTERED --allow-extra-chr \
    --extract plink.prune.in --geno 0.01 --make-bed \
    --out MERGED_3_FILTERED_MAC.LD_PRUNED_0.01
