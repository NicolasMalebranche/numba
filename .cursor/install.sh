#!/usr/bin/env bash
# Cloud Agent install script for Numba development.
#
# Numba's main (development) branch requires an unreleased llvmlite that is only
# published on the "numba/label/dev" conda channel, so this builds a conda
# environment mirroring buildscripts/incremental/setup_conda_environment.sh and
# then compiles Numba's C/C++ extensions in place.
set -euo pipefail

MINIFORGE_DIR="$HOME/miniforge3"
ENV_NAME="numba"
PYTHON_VERSION="3.12"
NUMPY_VERSION="2.2"

if [ ! -x "$MINIFORGE_DIR/bin/conda" ]; then
    curl -fsSL -o /tmp/miniforge.sh \
        https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    bash /tmp/miniforge.sh -b -p "$MINIFORGE_DIR"
    rm -f /tmp/miniforge.sh
fi

# shellcheck disable=SC1091
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

if ! conda env list | grep -qE "^${ENV_NAME}\s"; then
    conda create -n "$ENV_NAME" -y \
        -c numba/label/dev -c conda-forge \
        "python=${PYTHON_VERSION}" "numpy=${NUMPY_VERSION}" pip \
        gitpython pyyaml psutil cffi jinja2 pygments \
        "llvmlite=0.50"
fi

conda activate "$ENV_NAME"

python setup.py build_ext --inplace -j "$(nproc)"
python -m pip install --no-deps --no-build-isolation -e .

conda init bash >/dev/null
if ! grep -qxF "conda activate ${ENV_NAME}" "$HOME/.bashrc" 2>/dev/null; then
    echo "conda activate ${ENV_NAME}" >> "$HOME/.bashrc"
fi
