FROM dorowu/ubuntu-desktop-lxde-vnc:focal

# Set default environment variables
ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=password
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Add optional additional packages
USER root
RUN apt-get update && apt-get install -y \
    firefox \
    gedit \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a user for sudo access (optional)
RUN useradd -m -s /bin/bash desktopuser && \
    echo "desktopuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the user (optional)
USER desktopuser
