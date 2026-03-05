#!/bin/bash

############SLURM arguments#############

#SBATCH --job-name=DeepVariantGPU
#SBATCH --time=24:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 20
#SBATCH --mem=120G
#SBATCH --gres=localscratch:500G
#SBATCH --gpus=1
#SBATCH --partition=accel,a100
#SBATCH --output=slurm-%x_%j.out
#########################################

##############Main SCRIPT###################################
##Load Modules###
echo "SLURM partition assigned: $SLURM_JOB_PARTITION"

# Auto-detect the partition and load the correct module environment
if [[ "$SLURM_JOB_PARTITION" == "a100" ]]; then
    echo "Running on A100 partition - Swapping to Zen2Env"
    module --force swap StdEnv Zen2Env
else
    echo "Running on Accel (P100) partition - Using default Intel environment"
fi

module load TensorFlow/2.11.0-foss-2022a-CUDA-11.7.0
module swap GCCcore/11.3.0 GCCcore/13.2.0

##Variables###

arraylist=$1
cramdir=/cluster/projects/nn10039k/projects/CWD/maholmen/variant_calling/cram
ext=fasta
outdir=/cluster/projects/nn10039k/projects/CWD/maholmen/variant_calling/deepvariant
SIFIMAGE='/cluster/projects/nn10039k/shared/containers/singularity_apptainer/deepvariant_1.8.0-gpu.sif'
RSYNC='rsync -aLhv --no-perms --no-owner --no-group'

#####Array list######

LIST=$arraylist
input=$(head -n $SLURM_ARRAY_TASK_ID $LIST | tail -n 1)


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

# Hack to ensure that the GPUs work
nvidia-modprobe -u -c=0

## Copying data to local node for faster computation

cd $LOCALSCRATCH

echo "copying files to" $LOCALSCRATCH

wd=$(pwd)
echo "My working directory is "$wd
#Copy data to the $TMPDIR

echo "Copy singularity image to $LOCALSCRATCH ..."

time $RSYNC $SIFIMAGE .

echo "Copy cram file"

time $RSYNC $cramdir/$input.cram .

SAMPLE=$(basename $input .cram)
echo "working with this $SAMPLE sample"

echo "Copy crai file"

time $RSYNC $cramdir/$input.cram.crai .

#Copy reference
echo "Copy Reference and index"
time $RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/finalfasta_557_15K/557_15K_chromosome_upper_cases.fasta .
time $RSYNC /cluster/projects/nn10039k/projects/CWD/maholmen/finalfasta_557_15K/557_15K_chromosome_upper_cases.fasta.fai .
echo "My refs"
ls -1|grep $ext
REF=$(ls -1|grep $ext|grep -v .fai)
echo "This is my reference $REF"

#Create a directory to save results
mkdir $SAMPLE.deepvariant.GPU.dir

#Create a tmp dir for tmp results
mkdir deeptmp.dir
cd deeptmp.dir
DEEPTMP=$(pwd)
cd $wd
echo "I am on"
pwd

echo "Start deep variant..."
date +%d\ %b\ %T

# Run DeepVariant.

##Chec libraries and GPU is detected by the image

# Run TensorFlow GPU check inside Singularity
GPU_CHECK=$(singularity exec --nv \
    -B /usr/lib/locale/:/usr/lib/locale/ \
    -B $PWD:$PWD -B /cluster/software:/cluster/software \
    --env LD_LIBRARY_PATH=$LD_LIBRARY_PATH \
    deepvariant_1.8.0-gpu.sif \
    /usr/bin/python3 -c "import tensorflow as tf; gpus=tf.config.list_physical_devices('GPU'); print(len(gpus))")

echo "GPU check result: $GPU_CHECK"

# If no GPU is detected, cancel the SLURM job
if [ "$GPU_CHECK" -eq "0" ]; then
    echo "🚨 No GPU detected! Cancelling job $SLURM_JOB_ID..."
    scancel $SLURM_JOB_ID
    exit 1
fi

echo "✅ GPU detected! Running DeepVariant..."

time singularity run --nv \
-B /usr/lib/locale/:/usr/lib/locale/ \
-B $PWD:$PWD  \
-B /cluster/software:/cluster/software \
--env LD_LIBRARY_PATH=$LD_LIBRARY_PATH  \
deepvariant_1.8.0-gpu.sif \
run_deepvariant \
--model_type=WGS \
--ref="$REF" \
--reads="$input.cram"  \
--output_vcf="$SAMPLE.deepvariant.GPU.dir"/$SAMPLE.vcf.gz \
--output_gvcf="$SAMPLE.deepvariant.GPU.dir"/$SAMPLE.g.vcf.gz \
--sample_name=$SAMPLE \
--intermediate_results_dir $DEEPTMP \
--num_shards=$SLURM_CPUS_ON_NODE

rm -Rf $DEEPTMP


###########Moving results ############

echo "Moving results..."

time $RSYNC $SAMPLE.deepvariant.GPU.dir $outdir

echo "Final fastq results are in: "$outdir

rm $REF
rm -r $SAMPLE.deepvariant.GPU.dir
rm $input.cram
rm $input.cram.crai
rm deepvariant_1.8.0-gpu.sif
rm 557_15K_chromosome_upper_cases.fasta.fai

echo "these are the files that I forgot to remove"
ls

echo "I've done at"
