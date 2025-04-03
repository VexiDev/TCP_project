FROM debian:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        curl \
        xz-utils \
        git \
        tcpdump \
    && \
    rm -rf /var/lib/apt/lists/

# Set Zig version
ENV ZIG_VERSION=0.14.0

# Download and extract Zig
RUN curl -LO https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    tar -xf zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    mv zig-linux-x86_64-${ZIG_VERSION} /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig

# Verify installation
RUN zig version

