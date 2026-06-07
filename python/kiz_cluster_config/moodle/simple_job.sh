#!/bin/bash
#SBATCH --job-name=kco-job
#SBATCH --partition=p0
#SBATCH --qos=basic
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1G
#SBATCH --time=00:15:00
#SBATCH --output=myJob_%j.out
#SBATCH --error=myJob_%j.err

##### Steps to be executed on the compute node #####
hostname