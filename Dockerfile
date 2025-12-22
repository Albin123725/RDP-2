FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    USER=root \
    HOME=/root

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo "Asia/Kolkata" > /etc/timezone

# Install packages
RUN apt update && apt install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    wget \
    && apt clean

# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "password123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup with USER export
RUN echo '#!/bin/bash
export USER=root
export HOME=/root
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Get noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/master.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt/ && \
    mv /opt/noVNC-master /opt/novnc && \
    rm /tmp/novnc.tar.gz

EXPOSE 10000

# Start command
CMD echo "Starting VNC server as user: $(whoami)" && \
    vncserver :1 -geometry 1280x720 -localhost no && \
    echo "VNC started successfully" && \
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:10000 --web /opt/novnc && \
    tail -f /dev/null
