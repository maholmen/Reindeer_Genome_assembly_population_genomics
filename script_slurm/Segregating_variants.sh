#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=polymorphic_MAC
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=16
#SBATCH --partition=bigmem,normal
#########################################

dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2
BED=MERGED_3_FILTERED_MAC_10%_BED

#activate module
module --quiet purge  # Reset the modules to the system default
module load PLINK/2.00a3.7-foss-2022a

echo "changing to $dir"

cd $dir/POLYMORPHIC

for POP in FI VA FR RH IC LO; do
    plink --bfile $dir/$BED --allow-extra-chr --keep /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/${POP}_subset.txt \
        --mac 1 --make-bed --out ${POP}.polymorphic.variants
done

for POP in FI VA FR RH IC LO; do
    plink --bfile $dir/$BED --allow-extra-chr --keep /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/MAC_2/subset/${POP}_subset.txt \
        --mac 1 --make-bed --write-snplist --snps-only just-acgt --out ${POP}.polymorphic.SNP
done

# Output file
output_file="variant_counts.txt"
> "$output_file"  # Clear the file if it already exists

for log_file in *.log; do
    if [[ -f "$log_file" ]]; then
        # Extract number before "variants and"
        variants=$(grep -oP '^\K[0-9,]+(?= variants and)' "$log_file" | tr -d ',')

        if [[ -n "$variants" ]]; then
            echo "$log_file: $variants" >> "$output_file"
        else
            echo "$log_file: No match found" >> "$output_file"
        fi
    fi
done

echo "Done. Output saved to $output_file"
