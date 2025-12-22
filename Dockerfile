FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    USER=root \
    HOME=/root \
    DISPLAY=:1

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo "Asia/Kolkata" > /etc/timezone

# Install packages - USE TIGERVNC, NOT TIGHTVNC
RUN apt update && apt install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    wget \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    && apt clean

# Setup VNC directory
RUN mkdir -p /root/.vnc && \
    echo "password123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup for TigerVNC
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

# Start TigerVNC server
CMD echo "Starting XFCE VNC Desktop..." && \
    echo "Timezone: Asia/Kolkata" && \
    echo "Date: $(date)" && \
    echo "Starting VNC server..." && \
    /usr/bin/vncserver :1 \
        -geometry 1280x720 \
        -depth 24 \
        -dpi 96 \
        -localhost no \
        -alwaysshared \
        -SecurityTypes VncAuth \
        -rfbauth /root/.vnc/passwd && \
    sleep 3 && \
    echo "Starting noVNC web interface..." && \
    /opt/novnc/utils/novnc_proxy \
        --vnc localhost:5901 \
        --listen 0.0.0.0:10000 \
        --web /opt/novnc && \
    echo "✅ Desktop ready!" && \
    echo "🌐 https://[YOUR-SERVICE].onrender.com" && \
    echo "🔑 Password: password123" && \
    tail -f /dev/null
