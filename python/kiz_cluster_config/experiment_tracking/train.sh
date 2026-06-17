#!/bin/bash
#SBATCH --job-name=dermascan-efficientnet
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --time=03:00:00
#SBATCH --qos=basic
#SBATCH --output=/home/pichkuril97175/dermascan/logs/%j.out
#SBATCH --error=/home/pichkuril97175/dermascan/logs/%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=pichkuril97175@th-nuernberg.de

mkdir -p /home/pichkuril97175/dermascan/logs

/nfs/scratch/students/pichkuril97175/dermascan-env/bin/python /home/pichkuril97175/dermascan/python/kiz_cluster_config/experiment_tracking/train_config.py