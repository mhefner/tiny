FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y build-essential git cmake curl && \
    apt-get clean

# Build llama.cpp for ARM
RUN git clone https://github.com/ggerganov/llama.cpp.git /llama && \
    cd /llama && \
    make LLAMA_NATIVE=ON

WORKDIR /llama
COPY models /models

ENTRYPOINT ["./main"]

