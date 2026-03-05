#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=minimap2
#SBATCH --time=36:00:00
#SBATCH --mem=30G
#SBATCH --cpus-per-task=16
#SBATCH --partition=smallmem,hugemem-avx2
#SBATCH --output=slurm-%x_%A_%a.out
#SBATCH -e slurm-%x_%A_%a.err
#########################################

###############Main SCRIPT####################

##Variables###

LIST=$1 #array list
subdir=$2 # subdir in the fastp files, 120_population
RSYNC='rsync -aPLhv --no-perms --no-owner --no-group'

#####Array list######

input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)

##Load modules

echo "Activating minimap2 and SAMtools module for $USER"
module load minimap2
module load SAMtools
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

# copying fasta and indexed fasta
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fasta/557_15K_chromosome_upper_cases.fasta .
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fasta/557_15K_chromosome_upper_cases.fasta.fai .

ref=557_15K_chromosome_upper_cases.fasta

echo "copying Reads to" $wd
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fastp/$subdir/$input.R1.fastp.fq.gz .
$RSYNC /mnt/project/CWD_reindeer/maholmen_phd/fastp/$subdir/$input.R2.fastp.fq.gz .

echo "These are my files..."
ls -lrth

minimap2 \
-ax sr \
-t $SLURM_CPUS_ON_NODE \
$ref \
$input.R1.fastp.fq.gz \
$input.R2.fastp.fq.gz > $input.sam

rm *.fastp.fq.gz

##Samtools

echo "Sam to Bam..."

time samtools view \
-@ $SLURM_CPUS_ON_NODE \
-bS $input.sam > $input.bam

rm $input.sam

echo "Sorting Bam..."

time samtools sort \
-@ $SLURM_CPUS_ON_NODE $input.bam > $input.sorted.bam

samtools index $input.sorted.bam

rm $input.bam

echo "running statistics"

samtools stats $input.sorted.bam > $input.stat.txt

###########Moving results ############

#echo "Moving results..."

mkdir /mnt/project/CWD_reindeer/maholmen_phd/Minimap2/$input.minimap2.dir

$RSYNC $input* /mnt/project/CWD_reindeer/maholmen_phd/Minimap2/$input.minimap2.dir/

echo "Final fastq results are in: /mnt/project/CWD_reindeer/maholmen_phd/Minimap2"

####removing tmp dir. Remember to do this for not filling the HDD in the node!!!!###

cd $TMPDIR/$USER/
rm -r tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID

echo "I've done at"
