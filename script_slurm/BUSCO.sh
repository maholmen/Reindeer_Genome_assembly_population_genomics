#!/bin/bash

##############SLURM SCRIPT###################################

## Job name:
#SBATCH --job-name=BUSCOs
#
## Wall time limit:
#SBATCH --time=48:00:00
###Account
#SBATCH --account=nn10039k
## Other parameters:
#SBATCH --nodes 1
#SBATCH --cpus-per-task 18
#SBATCH --mem=80G
#SBATCH --gres=localscratch:500G
#SBATCH --partition=bigmem
#SBATCH --output=slurm-%x_%A_%a.out
#########################################   

#Variables
inputdir=$1 # where to find the file
input=$2 # input file
RSYNC='rsync -aPLh --no-perms --no-owner --no-group --no-t'
##Main script

##Activate conda environments ## Arturo

module --quiet purge  # Reset the modules to the system default
module load Anaconda3/2022.10

##Activate conda environments

export PS1=\$
source ${EBROOTANACONDA3}/etc/profile.d/conda.sh
conda deactivate &>/dev/null

conda activate /cluster/projects/nn10039k/shared/condaenvironments/BUSCO_5.5.0

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

echo "copying files to" $LOCALSCRATCH

$RSYNC $inputdir/$input .

##running BUsCO

echo "Starting BUSCO..."
date +%d\ %b\ %T

time busco \
-i $input \
-o $input.busco \
-m geno \
-l mammalia_odb10 \
-c $SLURM_CPUS_ON_NODE

cat $input.busco/short_summary.specific*.busco.txt |\
sed 's/\t//g'|\
perl -e 'while(<>){chomp;if($_ =~ /^C:/){(undef,$comple)=split(/:/,$_); $comple =~ s/\[S//g; $comple =~ s/\%//g; print "BUSCOscore\t$comple\n";}}' > $input.BUSCO.score.txt

echo "Compressing BUSCO dir"

time tar cf - $input.busco|\
pigz -p $SLURM_CPUS_ON_NODE > $input.busco.tar.gz

#Moving

$RSYNC $input.busco.tar.gz /cluster/projects/nn10039k/projects/CWD/maholmen/busco
$RSYNC $input.BUSCO.score.txt /cluster/projects/nn10039k/projects/CWD/maholmen/busco

echo "Done..."
date
