FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git make gcc g++ pkg-config \
  python3 python3-pip python3-venv \
  racket \
  llvm libnuma-dev \
  libgmp-dev zlib1g-dev \
  xz-utils \
  && rm -rf /var/lib/apt/lists/*

# Install stack (static binary); GHC will be managed by stack.
ARG STACK_VERSION=2.15.7
RUN curl -fsSL --retry 5 --retry-delay 2 --connect-timeout 10 --max-time 600 -o /tmp/stack.tgz \
      "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64.tar.gz" \
  && tar -xzf /tmp/stack.tgz -C /tmp \
  && mv /tmp/stack-*/stack /usr/local/bin/stack \
  && rm -rf /tmp/stack.tgz /tmp/stack-* \
  && chmod +x /usr/local/bin/stack

# Create a user matching the host default uid/gid (jalynk:1000)
RUN groupadd -g 1000 user && useradd -m -u 1000 -g 1000 -s /bin/bash user

USER user
WORKDIR /workspace
ENV HOME=/home/user
ENV PATH="/home/user/.local/bin:${PATH}"
