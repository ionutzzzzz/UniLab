# Stage 1: Build Rust Core
FROM rust:1.85-slim AS rust-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/unilab_core ./unilab_core
COPY backend/unilab_cli ./unilab_cli
RUN cargo build --release -p unilab_core

# Stage 2: Production Python
FROM python:3.12-slim
WORKDIR /app

# Install system dependencies for scientific libraries (headless)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libfontconfig1 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ ./backend/
# Copy built Rust library from builder stage for both PyO3 and FFI consumers
COPY --from=rust-builder /app/target/release/libunilab_core.so ./backend/core/unilab_rust_core.so
COPY --from=rust-builder /app/target/release/libunilab_core.so ./backend/core/engines/libunilab_core.so

# Set environment variables
ENV PYTHONPATH=/app
ENV UNILAB_WORKSPACE_ROOT=/app/workspaces
ENV UNILAB_API_SERVER=1
ENV MPLBACKEND=Agg
ENV QT_QPA_PLATFORM=offscreen

# Create workspaces directory
RUN mkdir -p /app/workspaces

# Expose port
EXPOSE 8000

# Single worker preserves in-memory UniLabCore session state
CMD ["gunicorn", "-w", "1", "-k", "uvicorn.workers.UvicornWorker", "backend.api.main:app", "--bind", "0.0.0.0:8000"]
