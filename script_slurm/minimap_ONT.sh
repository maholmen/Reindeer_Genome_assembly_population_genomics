#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=minimap2
#
## Wall time limit:
#SBATCH --time=96:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 16
#SBATCH --mem=50G
#SBATCH --gres=localscratch:500G
#SBATCH --partition=normal,bigmem
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################

##Variables

ontfile=$1 # the specific ONT file: 20230822_Rtar_1071_SRE-25kb.filtlong.fq.gz or 20230822_Rtar_557_SRE-25kb.filtlong.fq.gz
fastafiledir=$2 # the directory of the fastafile
fastafile=$3 # the fastafile
outname=$4 # the outname of the file


RSYNC='rsync -aPvLh --no-perms --no-owner --no-group'

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
$RSYNC /cluster/projects/nn10039k/projects/CWD/ONT_filterReads/$ontfile .

# notify that FastaFile is being copied
echo "Copying FastaFile..."

# Copies the fastafile to the localscratch
$RSYNC $fastafiledir/$fastafile .

time minimap2 \
-ax map-ont \
-t $SLURM_CPUS_ON_NODE \
$fastafile \
$ontfile > $outname.sam

# Change the sam file to a bam file
# Notifies that this is happening:
echo "Sam to Bam..."

time samtools view \
-@ $SLURM_CPUS_ON_NODE \
-bS $outname.sam > $outname.bam

# Removes the SAM file from the localscratch
rm $outname.sam

# Notifies what I am doing
echo "Sorting Bam..."

time samtools sort \
-@ $SLURM_CPUS_ON_NODE $outname.bam > $outname.sorted.bam

# making index file
samtools index -@ $SLURM_CPUS_ON_NODE -b $outname.sorted.bam > $outname.sorted.bam.bai

# removes the BAM file from the local scratch
rm $outname.bam

# moved the BAM file to the output directory of your choice

$RSYNC $outname.sorted.bam /cluster/projects/nn10039k/projects/CWD/maholmen/minimap
$RSYNC $outname.sorted.bam.bai /cluster/projects/nn10039k/projects/CWD/maholmen/minimap

echo "I've done"
