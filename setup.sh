#!/usr/bin/env bash

if [ -d .venv ]; then
    rm -rf .venv
fi

python -m venv .venv

source .venv/bin/activate

pip install --upgrade pip
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt

deactivate
