# GGUF Repack

`gguf-py` does not contain the conversion scripts or its related model modules. This repository repacks `gguf-py`, `conversion`, and `convert_hf_to_gguf.py` into a single repository.

## Setup

```sh
git clone https://github.com/teleprint-me/gguf-repack gguf-repack
cd gguf-repack
./build_gguf.sh
```

## Usage Example

`gguf/__main__.py` is renamed from `convert_hf_to_gguf.py`.

To view its help text:

```sh
python -m gguf -h
```

To convert a safetensors model file to a gguf model file:

```sh
python -m gguf /mnt/models/openai/gpt-oss-20b/ --outfile models/gpt-oss/gpt-oss-20b-bf16.gguf --outtype bf16
```

Then use `llama-quantize` (`llama.cpp`) to quantize model weights.

```sh
llama-quantize models/gpt-oss/gpt-oss-20b-bf16.gguf models/gpt-oss/gpt-oss-20b-mxfp4.gguf MXFP4_MOE
```

## Scripts

A shell script is used to automate syncing and building the `gguf-py` package.

`sync_gguf.sh` synchronizes llama.cpp module updates while preserving file attributes and hierarchy and updating only when files are out-of-date. 
