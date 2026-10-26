#!/usr/bin/env bash

if [ -d .venv ]; then
    rm -rf .venv
fi

python -m venv .venv

source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate
