#!/bin/bash

## Job name:
#SBATCH --job-name=FastP
#
## Wall time limit:
## Other parameters:
#SBATCH --cpus-per-task 12
#SBATCH --mem=50G
#SBATCH --partition=smallmem,hugemem-avx2
#SBATCH --out slurm-%x-%A_%a.out

# load model
module load fastp


###Variables###
LIST=$1
FASTQ=$2
outdir=$3
RSYNC='rsync -aLhv --no-group --no-perms'

#sbatch -a 1-90%10 fastp.sh FI_FR_LO.txt /mnt/project/CWD_reindeer/maholmen_phd/fastq/120_population /mnt/project/CWD_reindeer/maholmen_phd/fastp/120_population

#####Array list######

input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)

####Do some work:########

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
#MOVE fastq FILE TO TMPDIR

####### Copying data to local node for faster computation ####

# Check available space in TMPDIR
available_space=$(df -BG "$TMPDIR" | awk 'NR==2 {print $4}' | sed 's/G//')

# Define minimum required space (200GB)
required_space=200

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

echo "copying files to" $TMPDIR/$USER/tmpDir_of.$SLURM_JOB_ID

cd $USER
mkdir tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID
cd tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID
workdir=$(pwd)
echo "My working directory is" $workdir
echo "copying zip files ..."

echo "Input sample identifier: $input"

$RSYNC $FASTQ/$input.repaired.R1.fq.gz $workdir
$RSYNC $FASTQ/$input.repaired.R2.fq.gz $workdir

#FastP process
echo "QC of reads by FastP"
date +%d\ %b\ %T

time fastp \
        --in1 $input.repaired.R1.fq.gz \
        --in2 $input.repaired.R2.fq.gz \
        -w $SLURM_CPUS_ON_NODE \
        --out1 $input.R1.fastp.fq.gz \
        --out2 $input.R2.fastp.fq.gz \
        -h $input.fastp.report.html \
        -R $input.fastp.report \
        -q 30

##Copy files to the $SLURM_SUBMIT_DIR

echo "these are my files"
ls

$RSYNC $input.R1.fastp.fq.gz $outdir
$RSYNC $input.R2.fastp.fq.gz $outdir
$RSYNC $input.fastp.report.html $outdir

echo "The final cleaned reads are in $outdir"

cd $TMPDIR/$USER/
rm -r tmpDir_of.$SLURM_JOB_ID\_$SLURM_ARRAY_TASK_ID

echo "I've done at"
