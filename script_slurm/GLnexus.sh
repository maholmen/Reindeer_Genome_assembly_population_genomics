#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=GLNEXUS
#SBATCH --account=nn10039k
#SBATCH --time=24:00:00
#SBATCH --mem=1000G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A_%a.out
#SBATCH --cpus-per-task=16
#SBATCH --gres=localscratch:2000G
#SBATCH --partition=bigmem,hugemem,accel
#########################################

###Basic usage help for this script#######

print_usage() {
        echo "Usage: sbatch -a 1-<arrayindex> $0 arraylist Directory_bed_files Directory.w.vcFilestdir OutputDir"
        echo "e.g. sbatch -a 1-1 $0 listBED /mnt/project/Transpose/SNPs_deepvariant/BED $(pwd)/VCFFiles $(pwd)"
    }

if [ $# -le 1 ]
        then
                print_usage
                exit 1
elif [ $# -lt 4 ]
    then
        print_usage
                exit 1
elif [ $# -gt 4 ]
    then
        print_usage
                exit 1
    fi

###############Main SCRIPT###################################

##Variables###

arraylist=$1 # the name of the BED files
BEDDIR=$2 # directory of the BED files
RAW=$3 # directory of ALL .g.vcf.gz files
outdir=$4
RSYNC='rsync -aL --no-perms --no-owner --no-group --no-t'

# sbatch -a 1-2 glenexus.sh chromosome_bed_left.txt /cluster/projects/nn10039k/projects/CWD/maholmen/variant_calling/BED /cluster/projects/nn10039k/projects/CWD/maholmen/variant_calling/VCF /cluster/projects/nn10039k/projects/CWD/maholmen/variant_calling/glenexus/4_populations_chromosomes

#####Array list######

LIST=$arraylist
input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)

##Activate conda environments ## Arturo

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10

##Activate conda environments

export PS1=\$
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh
conda deactivate &>/dev/null

conda activate /cluster/projects/nn10039k/shared/condaenvironments/GLNEXUS

echo "I'm working with this CONDAENV"
echo $CONDA_PREFIX

###Do some work:########

## For debuggin
echo "Hello" $USER
echo "my submit directory is:"
echo $SLURM_SUBMIT_DIR
echo "this is the job:"
echo $SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID
echo "I am running on:"
echo $SLURM_NODELIST
echo "I am running with:"
echo $SLURM_CPUS_ON_NODE "cpus"
echo "Today is:"
date

## Copying data to local node for faster computation
echo "copying files to" $LOCALSCRATCH
cd $LOCALSCRATCH
wd=$(pwd)
echo "My working directory is "$wd
#Copy data to the $TMPDIR

echo "Copy BED Files"

time $RSYNC $BEDDIR/$input $wd

echo "My files"
ls -1

CRHOMNAME=$(echo $input|sed 's/.bed//g')

echo "Working on chromosome "$CRHOMNAME


##########GLNEXUS ##################
echo "Start GLNEXUS..."
date +%d\ %b\ %T

# Run GLNEXU on chromosome.

time glnexus_cli \
    --dir $wd/TMPDIR/ \
        --threads $SLURM_CPUS_ON_NODE \
        --mem-gbytes=20 \
        --config DeepVariantWGS\
        --bed $wd/$input \
        $RAW/*.g.vcf.gz > $CRHOMNAME.bcf #RAW is a directory with ALL the vcf files

echo "Done GLNEXUS"
time $RSYNC $CRHOMNAME.bcf* $outdir
##Converiting to vcf using bcftools
module load BCFtools/1.17-GCC-12.2.0
echo "Converting bcf to vcf.gz..."

time bcftools view $CRHOMNAME.bcf |\
    pigz -p $SLURM_CPUS_ON_NODE > $CRHOMNAME.bcf.vcf.gz

echo "Size use in $LOCALSCRATCH"

df -h $wd
###########Moving results ############

echo "Moving results..."

time $RSYNC $CRHOMNAME.bcf* $outdir

echo "Final results are in: "$outdir
echo "I've done at"
date
