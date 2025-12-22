FROM ubuntu:22.04

# Install everything in one command
RUN apt update && apt install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    wget \
    && apt clean

# Setup VNC password
RUN mkdir -p /root/.vnc
RUN echo "password123" | vpcpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd

# Create xstartup
RUN echo 'startxfce4' > /root/.vnc/xstartup
RUN chmod +x /root/.vnc/xstartup

# Download noVNC without git
RUN wget -q https://github.com/novnc/noVNC/archive/refs/heads/master.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt/ && \
    mv /opt/noVNC-master /opt/novnc && \
    rm /tmp/novnc.tar.gz

# Expose Render's port
EXPOSE 10000

# Start everything
CMD vncserver :1 -geometry 1280x720 -localhost no && \
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:10000 --web /opt/novnc && \
    tail -f /dev/null
