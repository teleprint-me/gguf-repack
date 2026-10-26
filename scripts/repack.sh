#!/usr/bin/env bash
# 1. Find every .py file under gguf – but skip __pycache__ dirs
# 2. For each file run sed in place, replacing the old import with the new one
# 3. Touch only the file that contains the imports.

find gguf -type f -name '*.py' -not -path '*/__pycache__/*' -exec \
    sed -i 's/from conversion/from gguf.conversion/g' {} +

sed -i -E \
  's/(__import__\(f")conversion\.([^"]*")/\1gguf.conversion.\2/g' \
  gguf/conversion/__init__.py
