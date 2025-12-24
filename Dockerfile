FROM ubuntu:22.04

# Install required packages
RUN apt update && apt install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    sudo \
    wget \
    --no-install-recommends

# Create user and directory
RUN useradd -m -s /bin/bash app && \
    echo "app:password" | chpasswd && \
    usermod -aG sudo app && \
    echo "app ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up RDP configuration
RUN mkdir -p /home/app/.config && \
    echo "startxfce4" > /home/app/.xsession && \
    chown -R app:app /home/app

# Configure xrdp
RUN sed -i 's/port=3389/port=$PORT/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/; autorun=x/autorun=x/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/^xserverbpp=.*$/xserverbpp=24/g' /etc/xrdp/xrdp.ini

# Clean up
RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Switch to app user
USER app

# Set display
ENV DISPLAY=:1

EXPOSE 3389

# Start xrdp
CMD ["xrdp", "--nodaemon"]
