#!/bin/bash

IMAGE="/nfs/scratch/students/$USER/python.sqsh"

srun --qos=interactive \
     --container-image=python \
     --container-save="$IMAGE" \
     true

srun --qos=interactive \
     --container-image="$IMAGE" \
     python -c 'print("hallo container")'