#!/usr/bin/env bash

# this script must be run from the root path of this repository.
# all paths are fixed and relative to gguf-repack directory path.

set -euo pipefail   # Abort on error, unset vars, propagate failures

# clean up python and build environment
function clean() {
    # note: not sure if .cache should be included
    rm -rf .venv .cache gguf gguf.egg-info dist
}

# set up python environment
function setup() {
    if [ -d .venv ]; then
        rm -rf .venv
    fi

    python -m venv .venv

    source .venv/bin/activate

    pip install --upgrade pip
    pip install -r requirements.txt

    deactivate
}

# sync gguf package
function sync() {
    # keep llama.cpp conversion helpers & gguf‑py utilities in sync
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

    # --- Paths ---
    LLAMA_ROOT=./.cache/llama.cpp   # Path to local llama.cpp clone
    GGUF_ROOT=./gguf                # Destination for gguf‑py helpers

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
}

# fix import paths
function update_import() {
    # 1. Find every .py file under gguf – but skip __pycache__ dirs
    # 2. For each file run sed in place, replacing the old import with the new one
    # 3. Touch only the file that contains the imports.

    find gguf -type f -name '*.py' -not -path '*/__pycache__/*' -exec \
        sed -i 's/from conversion/from gguf.conversion/g' {} +

    sed -i -E \
    's/(__import__\(f")conversion\.([^"]*")/\1gguf.conversion.\2/g' \
    gguf/conversion/__init__.py
}

# build gguf package
function build() {
    python -m build .
}

# 1. setup
# 2. sync
# 3. fix import references
# 4. build dist wheel
# All done!
