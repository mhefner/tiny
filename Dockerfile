FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

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

WORKDIR /llama

# Clone and build llama.cpp with server enabled
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    mkdir build && cd build && \
    cmake .. -G Ninja -DLLAMA_NATIVE=ON -DLLAMA_BUILD_SERVER=ON && \
    ninja && \
    ls -l

EXPOSE 8080

# This is now correct: the server binary is directly in /llama/build
ENTRYPOINT ["/llama/build/server"]

CMD ["-m", "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf", "--host", "0.0.0.0", "--port", "8080"]
