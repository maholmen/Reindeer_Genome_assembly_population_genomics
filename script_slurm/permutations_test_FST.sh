#!/bin/bash

#SBATCH --job-name=FST_perm
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=100G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=8
#SBATCH --partition=bigmem,normal

#########################################
#variables
PAIR=$1

# Paths
BASE_DIR=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_JUNE_2026/FST
PERM_DIR=$BASE_DIR/PERMUTATION/$PAIR
BED=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_JUNE_2026/MERGED_3_FILTERED_MAC.LD_PRUNED
POPFILE=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_JUNE_2026/subset/$PAIR.pop.txt

# Load PLINK
module --quiet purge
module load PLINK/2.00a3.7-foss-2022a

# Go to permutation directory
cd $PERM_DIR

# GET OBSERVED FST

OBS_FST=$(awk '/Weighted Fst estimate:/ {print $4}' $PAIR.fst.log)

echo "Observed FST: $OBS_FST"

# RUN PERMUTATIONS

N_PERM=500   

echo -e "perm_id\tfst" > perm_results.$PAIR.txt

for i in $(seq 1 $N_PERM); do

    echo "Running permutation $i"

    # create permuted population file
        awk '
    BEGIN{srand()}
    {
        id1=$1
        id2=$2
        pop[NR]=$3
        line[NR]=$1" "$2
    }
    END{
        # shuffle population labels
        for(i=NR;i>1;i--){
            j=int(rand()*i)+1
            tmp=pop[i]
            pop[i]=pop[j]
            pop[j]=tmp
        }
        # print shuffled file
        for(i=1;i<=NR;i++){
            print line[i], pop[i]
        }
    }' $POPFILE > perm_${i}.pop.txt

    # run plink
    plink --bfile $BED \
          --allow-extra-chr \
          --fst \
          --within perm_${i}.pop.txt \
          --out perm_${i}

    # extract FST
    fst=$(awk '/Weighted Fst estimate:/ {print $4}' perm_${i}.log)

    echo -e "${i}\t${fst}" >> perm_results.$PAIR.txt

    rm perm_${i}.* # to not produce to many files...

done

# CALCULATE P-VALUE (did once here and doubled checked in R)

PVAL=$(awk -v obs=$OBS_FST '
NR>1 { if($2 >= obs) count++ }
END { print count/(NR-1)}' perm_results.$PAIR.txt)

echo "P-value: $PVAL" > pvalue.$PAIR.txt

echo "Finished permutation test for $PAIR"
