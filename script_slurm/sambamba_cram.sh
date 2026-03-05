#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=sambamba_cram
#SBATCH --time=48:00:00
#SBATCH --mem=70G
#SBATCH --cpus-per-task=16
#SBATCH --partition=smallmem,hugemem-avx2
#SBATCH --output=slurm-%x_%A_%a.out
#SBATCH -e slurm-%x_%A_%a.err
#########################################

###############Main SCRIPT####################

##Variables###
LIST=$1 #the array

input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)

RSYNC='rsync -aPLhv --no-perms --no-owner --no-group'

## activate conda environment

module purge
echo "Activating Miniconda3 module for $USER"
module load Miniconda3
eval "$(conda shell.bash hook)"
echo "conda is running. Please type conda activate to load the basic conda functions..."
conda activate /net/fs-2/scale/OrionStore/Projects/CWD_reindeer/condaenvironments/SAMBAMBA
echo "I'm working with this CONDAENV"
echo $CONDA_PREFIX

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

# Check available space in TMPDIR
available_space=$(df -BG "$TMPDIR" | awk 'NR==2 {print $4}' | sed 's/G//')

# Define minimum required space (400GB)
required_space=500

# Evaluate space and terminate job if insufficient
if [[ $available_space -lt $required_space ]]; then
    echo "ERROR: Insufficient space in $TMPDIR. Available: ${available_space}GB, Required: ${required_space}GB."
    echo "Terminating array job $SLURM_ARRAY_JOB_ID..."
    scancel "$SLURM_ARRAY_JOB_ID"
    exit 1
else
    echo "Sufficient space available in $TMPDIR: ${available_space}GB."
fi


## Copying data to local node for faster computation

cd $TMPDIR

#Check if $USER exists in $TMPDIR

if [[ -d $USER ]]
        then
                echo "$USER exists on $TMPDIR"
        else
                mkdir $USER
fi


echo "copying files to" $TMPDIR/$USER

cd $USER
mkdir tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID
cd tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID
wd=$(pwd)
echo "My workdir is" $wd

#Copy data to the $TMPDIR

cd $wd

$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/Minimap2/$input.minimap2.dir/$input.sorted.bam .
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/Minimap2/$input.minimap2.dir/$input.sorted.bam.bai .
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fasta/557_15K_chromosome_upper_cases.fasta .
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fasta/557_15K_chromosome_upper_cases.fasta.fai .

ref=557_15K_chromosome_upper_cases.fasta

echo "Marking and removing duplicates with Sambamba..."
sambamba markdup -r -t $SLURM_CPUS_ON_NODE $input.sorted.bam $input.sambamba.bam


module purge
module load SAMtools

# indexing bam file
samtools index $input.sambamba.bam

# running stats
samtools stats $input.sambamba.bam > $input.sambamba_stat.txt

mkdir /mnt/project/CWD_reindeer/maholmen_phd/sambamba/$input.sambamba.dir

$RSYNC $input.sambamba.bam /mnt/project/CWD_reindeer/maholmen_phd/sambamba/$input.sambamba.dir
$RSYNC $input.sambamba.bam.bai /mnt/project/CWD_reindeer/maholmen_phd/sambamba/$input.sambamba.dir
$RSYNC $input.sambamba_stat.txt /mnt/project/CWD_reindeer/maholmen_phd/sambamba/$input.sambamba.dir

# converting to cram
echo "Cram..."

time samtools view \
-@ $SLURM_CPUS_ON_NODE \
-T $ref \
-C \
-o $input.cram \
-m 30G \
$input.sambamba.bam

echo "Index CRAM..."

samtools index $input.cram


$RSYNC $input.cram /mnt/project/CWD_reindeer/maholmen_phd/cram
$RSYNC $input.cram.crai /mnt/project/CWD_reindeer/maholmen_phd/cram

####removing tmp dir. Remember to do this for not filling the HDD in the node!!!!###

cd $TMPDIR/$USER/
rm -r tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID

echo "I've done at"
