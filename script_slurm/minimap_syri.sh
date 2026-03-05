#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=minimap2_syri
#
## Wall time limit:
#SBATCH --time=02:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 16
#SBATCH --mem=50G
#SBATCH --gres=localscratch:100G
#SBATCH --partition=normal
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################

##Variables
outname=$1 # the outname of the file
RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'
REF=$2
QUERY=$3

##Activate conda environments ## Arturo

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Loads the specfied verison of Anaconda
module load SAMtools/1.17-GCC-12.2.0 # Loads the SAMtools so it can be used 

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

# Copies all the files from the directory of fqfiles. 
$RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/syri/$REF .
$RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/syri/$QUERY .


minimap2 -ax asm5 --eqx -t $SLURM_CPUS_ON_NODE $REF $QUERY > $outname.sam

# Change the sam file to a bam file
# Notifies that this is happening: 
echo "Sam to Bam..."

samtools view -b $outname.sam > $outname.bam

# sort BAM file
time samtools sort \
-@ $SLURM_CPUS_ON_NODE $outname.bam > $outname.sorted.bam

# making index file
samtools index -@ $SLURM_CPUS_ON_NODE -b $outname.sorted.bam > $outname.sorted.bam.bai


# moved the BAM file to the output directory of your choice 
$RSYNC $outname.sorted.bam /cluster/projects/nn10039k/projects/CWD/maholmen/syri
$RSYNC $outname.sorted.bam.bai /cluster/projects/nn10039k/projects/CWD/maholmen/syri

echo "I've done"
date
