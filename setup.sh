#!/bin/bash

uv venv --python 3.9 .venv
source .venv/bin/activate
uv pip install numpy tensorboardx opt_einsum numba psutil pyyaml mpi4py cmake "cython==0.29.36" tensorboard einops h5py matplotlib scikit-learn scipy tqdm setuptools
# uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
uv pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/cu118
uv pip install transformers sentencepiece
cd diff-quaternion/TorchRotation
uv pip install -e . --no-build-isolation
cd ../..
cd ModifyODESrc
uv pip install -e . --no-build-isolation
bash clear.sh
cd ..
uv pip install -e .