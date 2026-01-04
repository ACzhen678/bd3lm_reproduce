#!/bin/bash
#SBATCH -J varlen_bd3lm                # Job name
#SBATCH -o watch_folder/%x_%j.out     # log file (out & err)
#SBATCH -e watch_folder/%x_%j.err     # log file (out & err)
#SBATCH -N 1                          # Total number of nodes requested
#SBATCH --get-user-env                # retrieve the users login environment
#SBATCH --mem=100000                  # server memory requested (per node)
#SBATCH -t 960:00:00                  # Time limit (hh:mm:ss)
#SBATCH --partition=gpu          # Request partition
#SBATCH --constraint="[a5000|a6000|3090|a100]"
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4                  # Type/number of GPUs needed
#SBATCH --open-mode=append            # Do not overwrite logs
#SBATCH --requeue                     # Requeue upon preemption

set -euo pipefail


LENGTH=512
SEED=3
BLOCK_SIZE=128

# NOTE:
# - Local Lightning `.ckpt` checkpoints should be loaded with `algo.backbone=dit`.
# - `algo.backbone=hf_dit` expects a HuggingFace model directory or Hub repo_id.

mkdir -p "$PWD/varlen_sample_logs"
mkdir -p "$PWD/.cache/huggingface"

export HF_HOME="$PWD/.cache/huggingface"
export HF_DATASETS_CACHE="$PWD/.cache/huggingface/datasets"
export TRANSFORMERS_CACHE="$PWD/.cache/huggingface/transformers"

python -u main.py \
    loader.eval_batch_size=1 \
    model=small \
    algo=bd3lm \
    algo.backbone=dit \
    algo.T=5000 \
    data=openwebtext-split \
    data.cache_dir=$PWD/.cache/huggingface/datasets \
    model.length=$LENGTH \
    block_size=$BLOCK_SIZE \
    wandb=null \
    mode=sample_eval \
    eval.checkpoint_path=$PWD/checkpoints/best_128_en.ckpt \
    eval.compute_gen_metrics=false \
    model.attn_backend=sdpa \
    seed=$SEED \
    sampling.nucleus_p=0.9 \
    sampling.kv_cache=true \
    sampling.logdir=$PWD/varlen_sample_logs/samples_genlen_bd3lm_blocksize${BLOCK_SIZE} \
    sampling.var_length=false