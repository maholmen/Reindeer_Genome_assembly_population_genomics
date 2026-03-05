#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=syri
## Wall time limit:
#SBATCH --time=04:00:00
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 4
#SBATCH --mem=50G
#SBATCH --partition=normal
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################

##Activate 

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Loads the specfied verison of Anaconda

export PS1=\$ # set the shell promt to just $, nicer output
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh # sources the Conda setup script to enable Conda commands in the current shell session
conda deactivate &>/dev/null # Deactivates any active Conda environment, redirecting any output to /dev/null to keep console clean

# activate the specifed Conda environment
conda activate /cluster/projects/nn10039k/shared/condaenvironments/SYRI

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

## variables
dir=$1
ref=$2
query=$3
bam=$4
outname=$5

RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'

cd $LOCALSCRATCH

$RSYNC $dir/$ref .
$RSYNC $dir/$query .
$RSYNC $dir/$bam* .

mkdir -p $outname
syri -c $bam -r $ref -q $query -k -F B --dir $outname

$RSYNC $outname/ $dir

rm $ref
rm $query
rm *$bam*
rm -r $outname
