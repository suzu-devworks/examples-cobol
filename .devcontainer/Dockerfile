FROM mcr.microsoft.com/devcontainers/base:ubuntu AS develop-stage

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN set -x \
    && apt update \
    && apt -y install --no-install-recommends apt-utils dialog 2>&1 \
    # Install libraries
    && apt -y install --no-install-recommends \
        gnucobol \
        uuid-dev \
    ;

# Clean up
RUN set -x \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/* \
    ;

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
