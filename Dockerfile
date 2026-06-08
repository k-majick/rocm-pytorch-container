FROM rocm/pytorch:latest

# Install ONNX export dependencies into /opt/venv
RUN /opt/venv/bin/pip install --no-cache-dir \
    onnxscript \
    onnx
