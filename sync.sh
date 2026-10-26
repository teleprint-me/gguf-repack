#!/usr/bin/env bash
#
# sync.sh – keep llama.cpp conversion helpers & gguf‑py utilities in sync
#
# The script performs the following steps:
#   1. Clone or pull the latest `llama.cpp` repository (under .cache/llama.cpp).
#   2. Create the target `gguf/` directory and its sub‑folders.
#   3. Copy the conversion helpers, gguf‑py scripts, and the core gguf
#      library from the repo to the local `gguf/` tree.
#   4. Install the HF‑to‑GGUF conversion script as `__main__.py` in the
#      root of the `gguf/` tree.
#
# Why `--update=older`?  
#   * preserves file timestamps & permissions (`-a`)  
#   * skips copying files that are newer locally (`--no-clobber`‑like)  
#   * keeps nested directory structure (`--parents`)  
#   * only copies if the source is newer (`--update=older`)  

set -euo pipefail   # Abort on error, unset vars, propagate failures

# --- Paths ---
LLAMA_ROOT=$(realpath ./.cache/llama.cpp)   # Path to local llama.cpp clone
GGUF_ROOT=$(realpath ./gguf)                # Destination for gguf‑py helpers

# Ensure the cache directory exists
mkdir -p .cache

# --- Clone / pull llama.cpp ---
if [ ! -d "$LLAMA_ROOT" ]; then
    git clone "https://github.com/ggml-org/llama.cpp" "$LLAMA_ROOT"
else
    git -C "$LLAMA_ROOT" pull --ff-only
fi

# --- Prepare destination ---
mkdir -p "$GGUF_ROOT/conversion" "$GGUF_ROOT/scripts"

# --- Copy conversion helpers ---
cp -a --update=older "$LLAMA_ROOT/conversion/."    "$GGUF_ROOT/conversion"

# --- Copy gguf‑py utilities ---
cp -a --update=older "$LLAMA_ROOT/gguf-py/gguf/scripts/." "$GGUF_ROOT/scripts"

# --- Copy core gguf library ---
cp -a --update=older "$LLAMA_ROOT/gguf-py/gguf/." "$GGUF_ROOT"

# --- Install HF→GGUF converter ---
cp -a --update=older "$LLAMA_ROOT/convert_hf_to_gguf.py" "$GGUF_ROOT/__main__.py"

echo "✅ gguf sync complete – everything is up‑to‑date."
