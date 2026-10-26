# GGUF Repack

`gguf-py` on its own does not ship the conversion utilities or the model modules that live in `llama.cpp`.  
`gguf-repack` pulls those pieces into a single repository and builds a wheel that contains the full set of tools, so you can convert Hugging‑Face models to GGUF, quantise them, and use them with `llama.cpp` without any manual copy‑paste.

## Setup

```bash
git clone https://github.com/teleprint-me/gguf-repack gguf-repack
cd gguf-repack
./build_gguf.sh
```

The script does everything for you:
1. Clones or updates the `llama.cpp` repository into `.cache/llama.cpp`.
2. Copies the `conversion` helpers, `gguf‑py` utilities, and the original `convert_hf_to_gguf.py` into a single `gguf/` package.
3. Builds a `gguf‑0.19.0-py3‑none‑any.whl` and a source distribution.

After the build you can install the package in any environment:

```bash
pip install dist/gguf-0.19.0-py3-none-any.whl
```

## Usage Example

The entry point is `gguf/__main__.py`, which is just the original `convert_hf_to_gguf.py` renamed for convenience.

```bash
# Show help
python -m gguf -h

# Convert a Hugging‑Face safetensors model to GGUF
python -m gguf /mnt/models/openai/gpt-oss-20b/ \
    --outfile models/gpt-oss/gpt-oss-20b-bf16.gguf \
    --outtype bf16
```

Once the GGUF file is created you can quantise it with the `llama.cpp` tool:

```bash
llama-quantize \
    models/gpt-oss/gpt-oss-20b-bf16.gguf \
    models/gpt-oss/gpt-oss-20b-mxfp4.gguf \
    MXFP4_MOE
```

## Scripts

| Script | Purpose |
|--------|---------|
| `sync_gguf.sh` | Pulls the latest changes from `llama.cpp` and updates the local copy, preserving timestamps and file hierarchies. |
| `build_gguf.sh` | Runs `sync_gguf.sh`, then builds the wheel (`python -m build`). |
| `repack.sh` | A quick helper that uses `find`/`sed` to adjust import paths after copying files. |

Feel free to modify or extend these scripts – they are intentionally simple and shell‑centric.