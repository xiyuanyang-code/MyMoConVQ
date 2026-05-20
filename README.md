# MyMoConVQ

## Install

- Python: 3.9
- CUDA Version: 12.2

```bash
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
```

### Data and Models

Pretrained data: Download from 

```
https://disk.pku.edu.cn/link/AAAFE3B2DDB1AC420EB5C4E0910196116F
```
or from OneDrive
```
https://1drv.ms/f/s!AsrkHbtkj4LsbqMZI08Bt9jFPJ4?e=SXkFlg
```

and place all file in this folder

Models: `models/t5_large` for https://huggingface.co/google-t5/t5-large.

## Quick Start for MoConVQ

```bash
# 1. motion construction to reconstruct a kinematic motion into physics-based version
# The `moconvq_base.data` contains a motion encoder and a physiscs-based motion decoder. 
python ./Script/track_something.py base.bvh

# * spliting the encoding and decoding process
# encoding
python ./Script/tokenize_motion.py track.bvh -o out/tokens.txt

# decoding
python ./Script/decode_token.py -i 166 410 332 149 419 237 172 305 192 273 174 -o out/decode.bvh

# unconditional motion generation
python ./Script/unconditional_generation.py --seed 123

# text-to-motion generation
python ./Script/text2motion_generation.py
```

### Detailed Documentation

The project ships 3 pretrained model files:

| Model File | Contents | Role |
|---|---|---|
| `moconvq_base.data` | MoConVQ (Encoder + Decoder) | Motion encoder (VQ-VAE) + physics-based motion decoder (tracking policy). The core model. |
| `unconditional_GPT.pth` | GPT (unconditional) | Autoregressive Transformer for unconditional motion generation in token space. |
| `text_generation_GPT.pth` | GPT (text-conditioned) | Cross-attention Transformer for text-driven motion generation in token space. |

1. Motion Reconstruction (encode + decode in one step)

Reconstruct a kinematic BVH motion into a physics-based version. The encoder maps the input motion into discrete tokens, then the physics-based decoder (a simulated tracking policy) replays the motion under full physical simulation (gravity, friction, collisions).

- **Input:** BVH file (kinematic motion from motion capture)
- **Output:** BVH file (physics-simulated motion)
- **Model used:** `moconvq_base.data` (both Encoder and Decoder)

2. Tokenize (encode only)

Encode a BVH motion into discrete token indices without running the physics simulation.

- **Input:** BVH file
- **Output:** Token index file (`.txt`, `.npz`, `.npy`, or `.h5`)
- **Model used:** `moconvq_base.data` (Encoder only)

3. Decode (decode only)

Decode a sequence of token indices into a physics-simulated BVH motion.

- **Input:** Token indices (via command line or file)
- **Output:** BVH file (physics-simulated motion)
- **Model used:** `moconvq_base.data` (Decoder only)

4. Unconditional Motion Generation

Generate a novel motion from scratch using the GPT model, then decode it through the physics simulator.

- **Input:** Random seed
- **Output:** BVH file (physics-simulated motion)
- **Models used:** `moconvq_base.data` + `unconditional_GPT.pth`
- **Pipeline:** GPT autoregressively generates tokens -> MoConVQ Decoder produces physics-based motion

5. Text-to-Motion Generation

Generate a motion from a natural language description. The text is first encoded with a T5 language model, then a cross-attention GPT generates motion tokens conditioned on the text features.

- **Input:** Text description (e.g., `"Take three steps forward, do a forward roll, then take three steps backward, and jump twice"`)
- **Output:** BVH file (physics-simulated motion)
- **Models used:** `moconvq_base.data` + `text_generation_GPT.pth` + T5 (`models/t5_large`)
- **Pipeline:** T5 encodes text -> cross-attention GPT generates tokens -> MoConVQ Decoder produces physics-based motion

### Architecture Overview

```
                            moconvq_base.data
                   +--------------------------------+
BVH -------------->  Encoder (VQ-VAE) --> tokens ---+
                   |                                |
                   |  Decoder (physics policy) <----+
                   +----------------+---------------+
                                    |
                                    v
                               Output BVH

Demo 1: BVH --> Encoder --> Decoder --> BVH            (moconvq_base.data)
Demo 2: BVH --> Encoder --> tokens                      (moconvq_base.data)
Demo 3: tokens --> Decoder --> BVH                      (moconvq_base.data)
Demo 4: seed --> GPT --> tokens --> Decoder --> BVH      (+ unconditional_GPT.pth)
Demo 5: text --> T5+GPT --> tokens --> Decoder --> BVH   (+ text_generation_GPT.pth + T5)
```