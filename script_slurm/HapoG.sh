#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=HapoG
#
## Wall time limit:
#SBATCH --time=36:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 16
#SBATCH --mem=450G
#SBATCH --gres=localscratch:500G
#SBATCH --partition=bigmem
#SBATCH --output=slurm-%x_%A_%a.out
#########################################

###############Main SCRIPT###################################

##Variables###

RSYNC='rsync -aPLvh --no-perms --no-owner --no-group --no-t'
Illumina1=$1 # first illumina file: Rtar_1071.R1.fastp.fq.gz or Rtar_557.R1.fastp.fq.gz
Illumina2=$2 # second illumina file: Rtar_1071.R2.fastp.fq.gz or Rtar_557.R2.fastp.fq.gz
Fastadir=$3 # the fastafile directory
Fastafile=$4 # the fasta file
Outname=$5 # the outname: ID_Overlap_flye/pepper

##Main script

##Activate conda environments

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10 # Load the specific version

##Activate conda environments

export PS1=\$ # makes the promt look nice
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh # sources the Conda setup script to enable Conda commands in the current shell session
conda deactivate &>/dev/null # Deactivates any active Conda environment, redirecting any output to /dev/null to keep console clean

# activate the specifed Conda environment
conda activate /cluster/projects/nn10039k/shared/condaenvironments/hapoG/

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

cd $LOCALSCRATCH

#Copy data to the $TMPDIR

echo "copying illumina Reads to" $LOCALSCRATCH
$RSYNC /cluster/projects/nn10039k/projects/CWD/illuminaReads/Ilmn4Polishing/Illumina4PpolishFastp/$Illumina1 .
$RSYNC /cluster/projects/nn10039k/projects/CWD/illuminaReads/Ilmn4Polishing/Illumina4PpolishFastp/$Illumina2 .

echo "Copy the fasta file"

$RSYNC $Fastadir/$Fastafile .

echo "These are my files:"
ls

##HapoG
echo "Starting polishing genome with HApoG"
date +%d\ %b\ %T

time hapog --genome $Fastafile \
    --pe1 $Illumina1 \
    --pe2 $Illumina2 \
    -o $Outname.Polished.HApoG.dir \
    -t $SLURM_CPUS_ON_NODE 2>&1 | tee $Outname.hapog_output.log

#Moving data to out
echo "Moving results to output"
$RSYNC $Outname.Polished.HApoG.dir /cluster/projects/nn10039k/projects/CWD/maholmen/hapog
$RSYNC $Outname.hapog_output.log /cluster/projects/nn10039k/projects/CWD/maholmen/hapog/$Outname.Polished.HApoG.dir

echo "Done..."
date
