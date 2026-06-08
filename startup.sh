#!/bin/bash
set -e

DEV_DIR="/workspace/rocm-pytorch"
REQ_FILE="$DEV_DIR/requirements.txt"
VENV_DIR="$DEV_DIR/.venv"
REQ_HASH_FILE="$VENV_DIR/.requirements_hash"

# 1. REMOVE /opt/venv from PATH so pip NEVER writes there
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '^/opt/venv' | paste -sd:)

# 2. Create project venv
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating project venv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

# 3. Activate project venv
source "$VENV_DIR/bin/activate"

# 4. Install project deps
CURRENT_HASH=$(sha256sum "$REQ_FILE" | awk '{print $1}')

if [ ! -f "$REQ_HASH_FILE" ] || [ "$CURRENT_HASH" != "$(cat "$REQ_HASH_FILE")" ]; then
    echo "🔄 Requirements changed — installing dependencies into .venv..."
    "$VENV_DIR/bin/pip" install --no-cache-dir -r "$REQ_FILE" -c "$DEV_DIR/constraints.txt"
    echo "$CURRENT_HASH" > "$REQ_HASH_FILE"
else
    echo "✔ Requirements unchanged — skipping installation."
fi

"$VENV_DIR/bin/pip" install --no-cache-dir --no-deps accelerate==0.30.1

# 5. Ensure ipykernel + JupyterLab exist in .venv
"$VENV_DIR/bin/pip" install --no-cache-dir ipykernel jupyterlab

# 6. Create kernel spec
"$VENV_DIR/bin/python" -m ipykernel install --user --name rocm-gpu --display-name "ROCm GPU"

# 7. Overwrite kernel.json to use /opt/venv Python + project PYTHONPATH
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
    "PYTHONPATH": "/workspace/rocm-pytorch/.venv/lib/python3.12/site-packages",
    "CUDA_VISIBLE_DEVICES": "0",
    "CUDA_DEVICE_ORDER": "PCI_BUS_ID",
    "CUDA_LAUNCH_BLOCKING": "1"
  }
}
EOF

echo "🚀 Starting Jupyter Lab..."
exec "$VENV_DIR/bin/jupyter" lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.disable_check_xsrf=True
