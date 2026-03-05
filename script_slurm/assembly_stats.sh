#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=statistics
#
## Wall time limit:
#SBATCH --time=06:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 8
#SBATCH --mem=50G
#SBATCH --gres=localscratch:100G
#SBATCH --partition=normal
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################
## Variables
inputdir=$1 #where are the files, make sure only the files you want to run statistics on is in this directory 
ext=$2 # extention, fasta, fna
outname=$3 # the name of the outputfile, syntax: whichfiles_stats
RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'
##Activate conda environments 

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Loads the specfied verison of Anaconda

##Activate conda environments

export PS1=\$ # set the shell promt to just $, nicer output
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh # sources the Conda setup script to enable Conda commands in the current shell session
conda deactivate &>/dev/null # Deactivates any active Conda environment, redirecting any output to /dev/null to keep console clean

# activate the specifed Conda environment
conda activate /cluster/projects/nn10039k/shared/condaenvironments/ONPTools

# Prints a message indicating which Conda environment is currently active
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
# change to the local scratch directory
cd $LOCALSCRATCH

# notify that the copying proces is starting
echo "copying files to" $LOCALSCRATCH

# copying the Pepper polished fasta files
$RSYNC $inputdir/*$ext .

## Doing the statistics 
# Syntax of the file: assembly-stats -t file1.fa file2.fa file3.fa > assembly_stats.tsv
assembly-stats -t *.$ext > $outname.tsv

# Notifying what you are doing + at what time it starts
# moved the BAM file to the output directory of your choice
echo "Moving to output directory"

$RSYNC $outname.tsv /cluster/projects/nn10039k/projects/CWD/maholmen/statistics

echo "I've done"
date
