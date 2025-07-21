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
RUN git clone https://github.com/ggerganov/llama.cpp.git . && \
    mkdir build && cd build && \
    cmake .. -G Ninja -DLLAMA_NATIVE=ON && \
    ninja && \
    ls -l bin && \
    cd ../examples/server && \
    mkdir build && cd build && \
    cmake .. -G Ninja && \
    ninja && \
    ls -l build

EXPOSE 8080

ENTRYPOINT ["/llama/examples/server/build/server"]

CMD ["-m", "/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf", "--host", "0.0.0.0", "--port", "8080"]
