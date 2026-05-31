#!/bin/bash
set -e

DEV_DIR="/workspace/rocm-dev"
REQ_FILE="$DEV_DIR/requirements.txt"
VENV_DIR="$DEV_DIR/.venv"
REQ_HASH_FILE="$VENV_DIR/.requirements_hash"

# Create venv if missing
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv to install project dependencies AND run Jupyter
source "$VENV_DIR/bin/activate"

CURRENT_HASH=$(sha256sum "$REQ_FILE" | awk '{print $1}')

if [ ! -f "$REQ_HASH_FILE" ] || [ "$CURRENT_HASH" != "$(cat $REQ_HASH_FILE)" ]; then
    echo "🔄 Requirements changed — installing dependencies..."
    pip install --no-cache-dir -r "$REQ_FILE" -c /workspace/rocm-dev/pip-constraints.txt
    echo "$CURRENT_HASH" > "$REQ_HASH_FILE"
else
    echo "✔ Requirements unchanged — skipping installation."
fi

pip install --no-cache-dir --no-deps accelerate==0.30.1


# Ensure Jupyter + ipykernel exist in venv
if ! python -c "import ipykernel" 2>/dev/null; then
    echo "📦 Installing ipykernel (missing)..."
    pip install --no-cache-dir ipykernel
else
    echo "✔ ipykernel already installed."
fi

if ! command -v jupyter >/dev/null 2>&1; then
    echo "📦 Installing JupyterLab (missing)..."
    pip install --no-cache-dir jupyterlab
else
    echo "✔ JupyterLab already installed."
fi

# Create kernel spec (temporary, points to venv)
python -m ipykernel install --user --name rocm-gpu --display-name "ROCm GPU"

# Overwrite kernel.json to point to /opt/venv/bin/python3 and load ipykernel from project venv
cat > /home/ubuntu/.local/share/jupyter/kernels/rocm-gpu/kernel.json << 'EOF'
{
  "argv": [
    "/opt/venv/bin/python3",
    "-m",
    "ipykernel",
    "-f",
    "{connection_file}"
  ],
  "display_name": "ROCm GPU",
  "language": "python",
    "env": {
      "PYTHONPATH": "/workspace/rocm-dev/.venv/lib/python3.12/site-packages",
      "CUDA_VISIBLE_DEVICES": "0",
      "CUDA_DEVICE_ORDER": "PCI_BUS_ID",
      "CUDA_LAUNCH_BLOCKING": "1"
    }
}
EOF

# Start Jupyter Lab INSIDE the venv (because jupyter is installed here)
echo "🚀 Starting Jupyter Lab..."
exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.disable_check_xsrf=True

