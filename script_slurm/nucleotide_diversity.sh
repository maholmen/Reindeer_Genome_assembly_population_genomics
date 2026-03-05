#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=nucelotide_diversity
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=50G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH -e slurm-%x_%j.err ##error file
#SBATCH --cpus-per-task=8
#SBATCH --partition=bigmem,normal
#########################################

cd /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/NUCLEOTIDE_DIVERSITY

VCF=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/VCF/MERGED_3_FILTERED_MAC_10%.vcf.gz

#activate module
module --quiet purge  # Reset the modules to the system default
module load VCFtools/0.1.16-GCC-12.3.0


for POP in FI VA FR RH IC LO; do
   vcftools --gzvcf $VCF --keep /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/SEMI_AND_ICELAND/NUCLEOTIDE_DIVERSITY/POP_files/${POP}_population.txt --window-pi 10000 --out ${POP}_pi_10Kb

    awk '{sum += $5; n++} END {print sum / n}' ${POP}_pi_10Kb.windowed.pi > average_${POP}_pi_10Kb.txt
done
