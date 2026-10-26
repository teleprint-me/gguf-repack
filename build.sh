#!/usr/bin/env bash
# ==============================================================
#  build.sh – helper for the gguf‑repack repository
#  --------------------------------------------------------------
#  * clean   – remove build artifacts
#  * setup   – create a fresh venv and install deps
#  * sync    – pull the latest llama.cpp repo and copy files
#  * update_import – adjust import statements for the local layout
#  * build   – run `python -m build`
#  * all     – run all build steps in chronological order.
#  * help    – show this help
#
#  Usage: ./build.sh <command> [args]
# ==============================================================

# ------------------------------------------------------------------
# 1. Common configuration
# ------------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # repo root
CACHE_DIR="$ROOT_DIR/.cache"
LLAMA_ROOT="$CACHE_DIR/llama.cpp"
GGUF_ROOT="$ROOT_DIR/gguf"
REQ_FILE="$ROOT_DIR/requirements.txt"

# ------------------------------------------------------------------
# 2. Utility helpers
# ------------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

# Create directories if missing
mkdir_if_missing() {
    local dir="$1"
    [[ -d "$dir" ]] || mkdir -p "$dir" || die "Could not create $dir"
}

# ------------------------------------------------------------------
# 3. Commands
# ------------------------------------------------------------------

clean() {
    echo "Cleaning build artifacts …"
    rm -rf .venv .cache "$GGUF_ROOT" "$GGUF_ROOT.egg-info" dist
}

setup() {
    echo "Setting up Python virtualenv …"
    rm -rf .venv
    python -m venv .venv
    # Activate in a subshell so we don’t pollute the current shell
    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r "$REQ_FILE"
    deactivate
}

sync() {
    local force=false
    # Parse optional --force flag
    while [[ "$1" == "--force" ]]; do
        force=true
        shift
    done

    echo "Synchronizing gguf helpers from llama.cpp …"

    # 1. Ensure cache dir exists
    mkdir_if_missing "$CACHE_DIR"

    # 2. Clone or update llama.cpp
    if [[ ! -d "$LLAMA_ROOT/.git" ]]; then
        echo "  • Cloning llama.cpp …"
        git clone "https://github.com/ggml-org/llama.cpp" "$LLAMA_ROOT"
    else
        echo "  • Pulling latest changes …"
        git -C "$LLAMA_ROOT" pull --ff-only
    fi

    # 3. Prepare destination dirs
    mkdir -p "$GGUF_ROOT/conversion" "$GGUF_ROOT/scripts"

    # 4. Copy conversion helpers
    echo "  • Copying conversion helpers …"
    rsync -a --update  "$LLAMA_ROOT/conversion/" "$GGUF_ROOT/conversion/"

    # 5. Copy gguf‑py utilities
    echo "  • Copying gguf‑py scripts …"
    rsync -a --update  "$LLAMA_ROOT/gguf-py/gguf/scripts/" "$GGUF_ROOT/scripts/"

    # 6. Copy core gguf library
    echo "  • Copying core gguf library …"
    rsync -a --update  "$LLAMA_ROOT/gguf-py/gguf/" "$GGUF_ROOT/"

    # 7. Install HF→GGUF converter
    echo "  • Installing HF→GGUF converter …"
    cp -a --update "$LLAMA_ROOT/convert_hf_to_gguf.py" "$GGUF_ROOT/__main__.py"

    # 8. Optional: force overwrite of __init__ if requested
    if $force; then
        echo "  • Overwriting __init__ (force)"
        rsync -a "$LLAMA_ROOT/gguf-py/gguf/__init__.py" "$GGUF_ROOT/__init__.py"
    fi
}

update_import() {
    echo "Updating import statements in local gguf tree …"
    # 1. Simple relative imports → package imports
    find "$GGUF_ROOT" -type f -name '*.py' -not -path '*/__pycache__/*' -exec \
        sed -i 's/from conversion/from gguf.conversion/g' {} +

    # 2. Dynamic imports via __import__
    sed -i -E \
        's/(__import__\(f")conversion\.([^"]*")/\1gguf.conversion.\2/g' \
        $GGUF_ROOT/conversion/__init__.py
}

build() {
    echo "Building wheel with \`python -m build\` …"
    source .venv/bin/activate
    python -m build .
    deactivate
}

help() {
    cat <<'EOF'
Usage: ./build.sh <command> [options]

Commands:
  clean                Remove build artifacts (.venv, .cache, dist, etc.)
  setup                Create a fresh Python virtualenv and install deps
  sync [--force]       Pull latest llama.cpp and copy files into gguf/
                       (use --force to overwrite __init__ if needed)
  update_import        Adjust import statements for the local layout
  build                Build the wheel (python -m build .)
  all                  Run all build steps in chronological order.
  help                 Show this help
EOF
}

# ------------------------------------------------------------------
# 4. Command dispatcher
# ------------------------------------------------------------------
case "$1" in
    clean)  clean   ;;
    setup)  setup   ;;
    sync)   shift; sync "$@" ;;
    update_import) update_import ;;
    build)  build   ;;
    all)
        clean
        setup
        shift; sync "$@";
        update_import
        build
        ;;
    help|--help|-h) help ;;
    *) echo "Unknown command: $1" >&2; help; exit 1 ;;
esac
