#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=FST
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=16
#SBATCH --partition=bigmem,normal
#########################################


#variables
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/FST/HET_0.01
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/HET_geno_0.01/HET

#activate module
module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

echo "changing to $dir"

cd $dir

########################### Fixation index ####################################################################

# FI.FR
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FI_FR.pop.txt \
      --out FI.FR.fst

# FI.VA
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FI.VA.pop.txt \
      --out FI.VA.fst

# FI.LO
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FI.LO.pop.txt \
      --out FI.LO.fst

# FI.RH
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FI.RH.pop.txt \
      --out FI.RH.fst

# FI.IC
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FI.IC.pop.txt \
      --out FI.IC.fst

# VA.FR
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/VA.FR.pop.txt \
      --out VA.FR.fst

# VA.LO
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/VA.LO.pop.txt \
      --out VA.LO.fst

# VA.RH
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/VA.RH.pop.txt \
      --out VA.RH.fst

# VA.IC
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/VA.IC.pop.txt \
      --out VA.IC.fst

# LO.FR
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/LO.FR.pop.txt \
      --out LO.FR.fst

# LO.RH
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/LO.RH.pop.txt \
      --out LO.RH.fst

# LO.IC
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/LO.IC.pop.txt \
      --out LO.IC.fst

# FR.RH
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FR.RH.pop.txt \
      --out FR.RH.fst

# FR.IC
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/FR.IC.pop.txt \
      --out FR.IC.fst

# RH.IC
plink --bfile $BED \
      --allow-extra-chr \
      --fst \
      --within /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/RH.IC.pop.txt \
      --out RH.IC.fst


# merge all results into one file for downstream analysis
output="all_fst_data.tsv"

# Optional: Add a header
echo -e "Filename\tColumn3" > "$output"

# Loop through all files ending in .fst.fst
for file in *.fst.fst; do
    awk -v OFS='\t' -v fname="$(basename "$file")" '{ print fname, $5 }' "$file" >> "$output"
done

# Output file
outfile="fst_summary.txt"

echo -e "File\tMean_Fst\tWeighted_Fst" > "$outfile"

for file in "$dir"/*.fst.log; do
  mean_fst=$(awk '/Mean Fst estimate:/ {print $4}' "$file")
  weighted_fst=$(awk '/Weighted Fst estimate:/ {print $4}' "$file")
  filename=$(basename "$file")
  echo -e "${filename}\t${mean_fst}\t${weighted_fst}" >> "$outfile"
done

echo "Summary saved to $outfile"
