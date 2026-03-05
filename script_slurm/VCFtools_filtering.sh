#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=vcf_filter
#SBATCH --account=nn10039k
#SBATCH --time=48:00:00
#SBATCH --mem=500G
#SBATCH --nodes=1
#SBATCH --output=slurm-%x_%A.out
#SBATCH --cpus-per-task=8
#SBATCH --gres=localscratch:600G
#SBATCH --partition=bigmem
#SBATCH -e slurm-%x_%j.err ##error file
#########################################

##Variables###
VCF_IN=MERGED_3.vcf
VCF_OUT=$2
dir=$3

RSYNC='rsync -aL --no-perms --no-owner --no-group --no-t'

##Activate module

module --quiet purge  # Reset the modules to the system default
module load VCFtools/0.1.16-GCC-12.3.0

echo "I am working with this module"
module list

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

set -x  # Enable debugging

## changing directory
cd $LOCALSCRATCH

echo "copying $VCF_IN to $LOCALSCRATCH"

$RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/VARIANT_CALLING/GLnexus/$VCF_IN .

echo "checking that the file is here"

ls -l

echo my input file is "$VCF_IN"
echo "my output file will be $VCF_OUT"

# set filters
MAC=2 
MISS=0.9  
QUAL=30
MIN_DEPTH=6
MAX_DEPTH=30

#echo "MAC is $MAC"
echo "MISS is $MISS"
echo "QUAL is $QUAL"
echo "MIN_DEPTH is $MIN_DEPTH"
echo "MAX_DEPTH is $MAX_DEPTH"

echo "starting filtering"

vcftools --gzvcf $VCF_IN \
--mac $MAC --minQ $QUAL \
--min-meanDP $MIN_DEPTH --max-meanDP $MAX_DEPTH \
--minDP $MIN_DEPTH --maxDP $MAX_DEPTH --max-missing $MISS --recode --stdout | gzip -c > \
$VCF_OUT

echo "transferring file to $dir"

$RSYNC $VCF_OUT $dir
