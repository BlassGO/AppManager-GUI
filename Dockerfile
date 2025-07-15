# Using Debian 12 for compatibility
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Flutter dependencies
RUN apt update && apt install -y \
    git \
    curl \
    unzip \
    build-essential \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libglib2.0-dev \
    libgtk-3-dev \
    libappindicator3-dev \
    libgdk-pixbuf2.0-dev \
    libstdc++-12-dev \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

# Pre-cache Flutter binaries for Linux to speed up builds
RUN flutter precache --linux

# Extra configs
WORKDIR /app
COPY . .
RUN flutter config --enable-linux-desktop

# Build
RUN flutter pub get
RUN flutter build linux --release