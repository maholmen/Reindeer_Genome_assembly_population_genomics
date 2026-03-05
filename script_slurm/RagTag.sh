#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=ragtag
#
## Wall time limit:
#SBATCH --time=02:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 8
#SBATCH --mem=50G
#SBATCH --gres=localscratch:50G
#SBATCH --partition=normal
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################
## Variables
querydir=$1 #the directory of the query file
query=$2 # the query fiel to be aligned to the reference
reference=$3 # the reference file caribou_GCA_019903745.2.chromosome.fna, svalbard_GCA_949782905.chromosome.fna
outname=$4 # the name of the outputfile, syntax: reference_query (example_caribou_557)
RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'
##Activate conda environments

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Loads the specfied verison of Anaconda

##Activate conda environments

export PS1=\$ # set the shell promt to just $, nicer output
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh # sources the Conda setup script to enable Conda commands in the current shell session
conda deactivate &>/dev/null # Deactivates any active Conda environment, redirecting any output to /dev/null to keep console clean

# activate the specifed Conda environment
conda activate /cluster/projects/nn10039k/shared/condaenvironments/RAGTAG

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

# copying the reference genome
$RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/public_genomes/public_fasta/chromosome_fasta/$reference .


# copying the query
$RSYNC $querydir/$query .


## Running ragtag
ragtag.py scaffold $reference $query -o $outname.ragtag


# Notifying what you are doing + at what time it starts
# moved the BAM file to the output directory of your choice
echo "Moving to output directory"

$RSYNC $outname.ragtag /cluster/projects/nn10039k/projects/CWD/maholmen/ragtag

echo "I've done"
date
