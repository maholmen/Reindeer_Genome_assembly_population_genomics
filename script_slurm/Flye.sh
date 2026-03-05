#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=Flye
#
## Wall time limit:
#SBATCH --time=240:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 24
#SBATCH --mem=350G
#SBATCH --gres=localscratch:500G
#SBATCH --partition=bigmem,hugemem
#SBATCH --output=slurm-%x_%A_%a.out
#########################################

###Basic usage help for this script#######
# This defines a function print usage () that prints a usage messange.
# "$0" refers to the name of the script, so it dynamically shows how to run the script:

print_usage() {
        echo "Usage: sbatch $0 inputdir outname outdir overlap"

}

# This checks if the number of arguments passed to the script ($#) is less than 3.
# If it is, it calls the prints_usage function and exits the script with a status code of 1 (indcating an error)

if [ $# -lt 3 ]
        then
                print_usage
                exit 1
        fi


###############Main SCRIPT####################

##Variables###
# $1 refers to what you put into the command after the script, $2 the one after and so on
ONTfile=$1 #which ONT-file is being copied and worked with, two options: 20230822_Rtar_1071_SRE-25kb.filtlong.fq.gz or 20230822_Rtar_557_SRE-25kb.filtlong.fq.gz
outname=$2 # what should be the name of the assembly, syntax: reindeerID_overlap, example: 557_10K
overlap=$3 # which overlap you are working with: 10000 15000 25000
RSYNC='rsync -aL --no-perms --no-owner --no-group'

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

# notify which files are being copied
echo "copying Reads to" $LOCALSCRATCH

# copy filefrom the input directory to the current directory
$RSYNC /cluster/projects/nn10039k/projects/CWD/ONT_filterReads/$ONTfile .


####Assembly#######################

echo "Starting assembly by Flye...."
date +%d\ %b\ %T

echo "I am assembly with $overlap overlap"

time flye \
--nano-raw $ONTfile \
--min-overlap $overlap \
--genome-size 2.7g \
--out-dir $outname.flye.outdir \
-t $SLURM_CPUS_ON_NODE

###Moving files to outdir

time $RSYNC $outname.flye.outdir /cluster/projects/nn10039k/projects/CWD/maholmen/FastaAssemblies

echo "I've done at"
