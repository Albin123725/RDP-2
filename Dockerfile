FROM ubuntu:22.04

# Set environment to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

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
    locales \
    && apt-get clean

# Set locale to English (India)
RUN locale-gen en_IN.UTF-8
ENV LANG=en_IN.UTF-8
ENV LANGUAGE=en_IN:en
ENV LC_ALL=en_IN.UTF-8

# Setup VNC
RUN mkdir -p /root/.vnc && \
    echo "password123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd && \
    echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo 'exec startxfce4' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Get noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/master.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt/ && \
    mv /opt/noVNC-master /opt/novnc && \
    rm /tmp/novnc.tar.gz

# Configure XFCE for India/Asia
RUN mkdir -p /root/.config/xfce4 && \
    echo '[General]' > /root/.config/xfce4/helpers.rc && \
    echo 'TerminalEmulator=xfce4-terminal' >> /root/.config/xfce4/helpers.rc && \
    echo 'FileManager=Thunar' >> /root/.config/xfce4/helpers.rc

# Expose Render's port
EXPOSE 10000

# Start everything
CMD echo "Starting XFCE VNC Desktop (India Timezone)..." && \
    echo "Current time: $(date)" && \
    echo "Timezone: $(cat /etc/timezone)" && \
    vncserver :1 -geometry 1280x720 -localhost no && \
    sleep 2 && \
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:10000 --web /opt/novnc && \
    tail -f /dev/null
