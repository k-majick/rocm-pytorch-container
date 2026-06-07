# ROCm PyTorch Development Container

This repository provides a ready‑to‑use Docker environment for machine learning and LLM experimentation on AMD GPUs using ROCm.  
It wraps the official `rocm/pytorch:latest` image with additional tools such as JupyterLab, HuggingFace Transformers, FastAPI, OpenCV, PDF processing utilities, and other common ML dependencies.

The setup includes:
- `docker-compose-ROCm.yml` — GPU‑enabled container configuration  
- `startup.sh` — initialization script for installing Python packages  
- `requirements.txt` — curated list of ML/LLM libraries  
- Workspace mounted into `/workspace` for seamless development  

Ideal for training, prototyping, and running GPU‑accelerated notebooks.
