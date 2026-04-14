#!/bin/bash
# MoConVQ 环境安装脚本 (使用 uv 和 Python 3.9)

set -e 

echo "========================================="
echo "  MoConVQ 环境安装 (uv + Python 3.9)"
echo "========================================="
echo ""

# 1. 创建 Python 3.9 虚拟环境
echo "1. 创建 Python 3.9 虚拟环境..."
if [ ! -d ".venv" ]; then
    uv venv --python 3.9 .venv
    echo "✓ 虚拟环境创建完成"
else
    echo "✓ 虚拟环境已存在"
fi
echo ""

source .venv/bin/activate
uv pip install numpy tensorboardx opt_einsum numba psutil pyyaml mpi4py cmake "cython==0.29.36" tensorboard einops h5py matplotlib scikit-learn scipy tqdm setuptools
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
uv pip install transformers sentencepiece

cd diff-quaternion/TorchRotation
if uv pip install -e . --no-build-isolation 2>/dev/null; then
    echo "✓ RotationLibTorch 构建成功"
else
    echo "⚠ RotationLibTorch 构建失败"

cd ../..

cd ModifyODESrc
uv pip install -e . --no-build-isolation
cd ..

uv pip install -e .
echo "✓ MoConVQ 核心包安装完成"