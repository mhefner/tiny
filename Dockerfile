FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    ninja-build \
    libopenblas-dev \
    libcurl4-openssl-dev \
    && apt-get clean

# Build llama.cpp with CMake + Ninja
WORKDIR /llama
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    mkdir build && cd build && \
    cmake .. -G Ninja -DLLAMA_NATIVE=ON && \
    ninja && \
    ls -l bin

# Expose the HTTP server port for llama.cpp
EXPOSE 8080

# Use the server binary for API access
ENTRYPOINT ["/llama/build/bin/server"]


