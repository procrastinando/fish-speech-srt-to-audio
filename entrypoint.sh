#!/bin/bash

CUDA_ENABLED=${CUDA_ENABLED:-true}
DEVICE=""

if [ "${CUDA_ENABLED}" != "true" ]; then
    DEVICE="--device cpu"
fi

exec python tools/webui.py ${DEVICE} --llama-checkpoint-path checkpoints/fish-speech-1.4 --decoder-checkpoint-path checkpoints/fish-speech-1.4/firefly-gan-vq-fsq-8x1024-21hz-generator.pth --compile
