#!/usr/bin/env bash

# sync.sh
#
# Due to breaking changes in the llama.cpp gguf-py package and the lack of
# proper upstream PyPI updates, I’ve manually repackaged gguf-py into its
# own unified package which includes CLI tool usage.
#
# When the llama.cpp core ABI changes, the model can break and need to be
# "updated".  This means converting the original model weights from the
# source format into GGUF again, which requires having the original
# weights available.
#
# `convert_hf_to_gguf.py` can convert PyTorch or safetensors models to
# GGUF format.  For example:
#
#   python -m agent.gguf \
#       /mnt/models/p-e-w/gpt-oss-20b-heretic-ara-v3 \
#       --outfile models/gpt-oss/gpt-oss-20b-heretic-ara-bf16.gguf \
#       --outtype bf16
#
# The above command converts the HF checkpoint to a BF16‑quantized GGUF
# file.
#
# Note: each update breaks the API.
# A manual review is required before committing changes.
#
#  - `cp -a` preserves attributes (mtime, perms, etc.)
#  - `--no-clobber` avoids accidentally overwriting something you
#    might want to keep and keeps any local tweaks you might have made.
#  - `--parents` preserves the directory hierarchy if it contains nested folders.
#  - `--update` only when local files are `older` than upstream files.

set -euo pipefail        # Bail on errors, use unset vars, propagate pipes

# ---
#  Paths
# ---
declare -r LLAMA="${PWD}/.cache/llama.cpp"
declare -r GGUF="${PWD}/gguf"

if [ ! -d .cache ]; then
    mkdir .cache
fi

if [ ! -d .cache/llama.cpp ]; then
    # repo doesn't exist locally, clone it
    git clone "https://github.com/ggml-org/llama.cpp" .cache/llama.cpp
else
    # repo does exist, pull latest llama.cpp
    git -C "$LLAMA" pull --ff-only
fi

# ---
#  Make sure the target dir exists
# ---
mkdir -p "$GGUF/conversion" "$GGUF/scripts"

# ---
# Copy the conversion helpers
# ---
cp -a --update=older "$LLAMA/conversion/." "${GGUF}/conversion"

# ---
# Copy the GGUF‑Py utilities
# ---
cp -a --update=older "$LLAMA/gguf-py/gguf/scripts/." "${GGUF}/scripts"

# ---
# Copy the core library (the `gguf/` folder itself)
# ---
cp -a --update=older "$LLAMA/gguf-py/gguf/." "$GGUF/"

# ---
# Copy the conversion script into the repo root
# ---
cp -a --update=older "$LLAMA/convert_hf_to_gguf.py" "${GGUF}/__main__.py"

echo "✅ gguf sync complete – everything is up‑to‑date."
