#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=genome_wide
#SBATCH --account=nn10039k
#SBATCH --time=02:00:00
#SBATCH --mem=20G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A_%a.out
#SBATCH --cpus-per-task=6
#SBATCH --partition=normal
########################################

arraylist=$1
dir=/cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_AUGUST_2026/heterozygosity/deepvariant

module load BCFtools/1.22-GCC-14.3.0

LIST=$arraylist
input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)

cd $dir/$input.deepvariant.GPU.dir

echo $input

zcat $input.g.vcf.gz | \
awk '
BEGIN{
    callable=0
    het=0
}

/^#/ {next}

{
    split($10,fmt,":")

    gt=fmt[1]

    # Ignore missing genotypes
    if(gt=="./.")
        next

    # Reference block
    if($8 ~ /END=/){

        dp=fmt[3]

        if(dp>=6 && dp<=30){

            split($8,a,"END=")
            end=a[2]

            callable += (end-$2+1)
        }
    }

    # Variant site
    else{

        gq=fmt[2]
        dp=fmt[3]

        if($6>=30 && dp>=6 && dp<=30){

            callable++

            split(gt,b,/\/|\|/)

            if(b[1]!=b[2])
                het++
        }
    }
}

END{
    print "Callable_bp:",callable
    print "Het_sites:",het
    print "Hets_per_kb:",1000*het/callable
}' > "${input}.heterozygosity.txt"

mv ${input}.heterozygosity.txt /cluster/projects/nn10039k/projects/CWD/maholmen/POPULATION_GENETICS/REVISION_AUGUST_2026/heterozygosity/results
