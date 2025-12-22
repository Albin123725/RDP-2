FROM ubuntu:22.04

# Set environment to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata
ENV USER=root
ENV HOME=/root
ENV DISPLAY=:1

# Set India timezone before installing packages
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Install everything
RUN apt-get update && \
    apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    wget \
    tzdata \
    && apt-get clean

# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "password123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo 'export USER=root' >> /root/.vnc/xstartup && \
    echo 'export HOME=/root' >> /root/.vnc/xstartup && \
    echo 'exec startxfce4' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Get noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/master.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt/ && \
    mv /opt/noVNC-master /opt/novnc && \
    rm /tmp/novnc.tar.gz

# Expose Render's port
EXPOSE 10000

# Start everything with USER environment variable
CMD echo "Starting XFCE VNC Desktop (India Timezone)..." && \
    echo "Current time: $(date)" && \
    echo "Timezone: $(cat /etc/timezone)" && \
    echo "USER: $USER" && \
    echo "HOME: $HOME" && \
    export USER=root && \
    export HOME=/root && \
    vncserver :1 -geometry 1280x720 -localhost no && \
    sleep 2 && \
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:10000 --web /opt/novnc && \
    tail -f /dev/null
