#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=PEPPER
#
## Wall time limit:
#SBATCH --time=96:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 20
#SBATCH --mem=120G
#SBATCH --gres=localscratch:1024G
#SBATCH --gpus=1
#SBATCH --partition=accel
#SBATCH --output=slurm-%x_%j.out
#########################################

###############Main SCRIPT####################

##Variables
inputdir=$1 # directory of the fasta file
bamdir=$2 # directory of the BAM file
name=$3 # the prefix of the file, this should be the same for the fasta file, bam file and bai file. And will also give rise for the output name
RSYNC='rsync -aPLhv --no-perms --no-owner --no-group'

##Activate conda environments 

module --quiet purge  # Reset the modules to the system default
module load PyTorch/1.12.1-foss-2022a-CUDA-11.7.0

echo "Working with this module"
module list

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

echo "copying files to" $LOCALSCRATCH

echo "copying bam and bai to" $LOCALSCRATCH

$RSYNC $bamdir/$name.sorted.bam .
$RSYNC $bamdir/$name.sorted.bam.bai .

echo "Copying FastaFile..."

$RSYNC $inputdir/$name.flye.fasta .

# For the Pepper polishing you need some pictures:
echo "Copy image..."

$RSYNC /cluster/projects/nn10039k/shared/containers/singularity_apptainer/pepper_deepvariant_r0.7-gpu.sif .

# and something else
echo "copy db"
$RSYNC /cluster/projects/nn10039k/shared/DB/PEPPER_MODELS/pepper_r941_guppy344_human.pkl .
echo "my files"
ls -1


#PEPER
#Test nvidia

nvcc --version #checks the version of NVCC (NVIDA CUDA Compiler)
nvidia-smi #gives detailed information about NIVIDA GPU devices installed in the system

echo "PEPER..."
date +%d\ %b\ %T

time singularity run --nv -B $PWD:$PWD pepper_deepvariant_r0.7-gpu.sif pepper polish \
--bam $name.sorted.bam \
--fasta $name.flye.fasta \
--model_path pepper_r941_guppy344_human.pkl \
--output_file $name.PEPPER \
--threads $SLURM_CPUS_ON_NODE \
--batch_size 512 \
--gpu \
--num_workers 20

#Moving data

time $RSYNC $name.PEPPER* /cluster/projects/nn10039k/projects/CWD/maholmen/pepper

#DOne

echo "I've done at..."
date
