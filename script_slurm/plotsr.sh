#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=plotsr
#
## Wall time limit:
#SBATCH --time=01:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 4
#SBATCH --mem=50G
#SBATCH --gres=localscratch:50G
#SBATCH --partition=normal
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################

##Variables
InputDir=$1 # the directory of the Syri file (for easier execution, genomes file should also be stored here)
Syri=$2 # the syri output file. Syri.out 
Genomes=$3 # text file that contains the path to the genomes and the desiered name
Outname=$4 # desiered outname 
OutDir=$5 # teh desired output directory 

RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'

##Activate conda environments 

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Loads the specfied verison of Anaconda

##Activate conda environments

export PS1=\$ # set the shell promt to just $, nicer output 
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh # sources the Conda setup script to enable Conda commands in the current shell session
conda deactivate &>/dev/null # Deactivates any active Conda environment, redirecting any output to /dev/null to keep console clean

# activate the specifed Conda environment 
conda activate /cluster/projects/nn10039k/shared/condaenvironments/PLOTSR

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


# change to the local scratch directory 
cd $LOCALSCRATCH

# Copies the files to the localscratch 
$RSYNC $InputDir/$Syri .
$RSYNC $InputDir/$Genomes .

# runnig plotsr
plotsr \
    --sr $Syri \
    --genomes $Genomes \
    -o $Outname.pdf

# move the file to the output directory of your choice 
$RSYNC $Outname.pdf $OutDir

echo "I've done"
date
