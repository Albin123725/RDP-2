FROM ubuntu:22.04

# Set environment variables for Render
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    DISPLAY=:99 \
    RESOLUTION=1280x720x24 \
    USER=ubuntu \
    HOME=/home/ubuntu

# Create user (Render runs as non-root)
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/ubuntu/.vnc && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Install system packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    curl \
    xvfb \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    novnc \
    websockify \
    firefox \
    sudo \
    dbus-x11 \
    x11-utils \
    xterm \
    pulseaudio \
    net-tools \
    procps \
    htop \
    nano \
    vim \
    gnome-terminal \
    fonts-noto \
    && rm -rf /var/lib/apt/lists/*

# Set VNC password (optional, remove for no password)
RUN echo "password123" | x11vnc -storepasswd - && \
    mv /root/.vnc/passwd /home/ubuntu/.vnc/passwd 2>/dev/null || true && \
    chown ubuntu:ubuntu /home/ubuntu/.vnc/passwd 2>/dev/null || true

# Create startup script for Render
RUN echo '#!/bin/bash

# Set environment
export DISPLAY=:99
export HOME=/home/ubuntu
export USER=ubuntu
export PATH=$PATH:/usr/games

# Create necessary directories
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
chown root:root /tmp/.X11-unix

# Start Xvfb (virtual display)
echo "Starting Xvfb virtual display..."
Xvfb $DISPLAY -screen 0 ${RESOLUTION} -ac +extension GLX +render -noreset > /tmp/xvfb.log 2>&1 &
XVFB_PID=$!
sleep 3

# Check if Xvfb started
if ! ps -p $XVFB_PID > /dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

# Start dbus
echo "Starting dbus..."
dbus-launch --sh-syntax > /tmp/dbus.env 2>&1
source /tmp/dbus.env

# Start Xfce desktop
echo "Starting Xfce desktop..."
sudo -u ubuntu startxfce4 > /tmp/xfce.log 2>&1 &
XFCE_PID=$!
sleep 5

# Start x11vnc server
echo "Starting VNC server..."
x11vnc -display $DISPLAY \
    -forever \
    -shared \
    -nopw \
    -listen 0.0.0.0 \
    -rfbport 5900 \
    -noxdamage \
    -repeat \
    -cursor arrow \
    -nowf \
    -wait 5 \
    -defer 5 > /tmp/x11vnc.log 2>&1 &
VNC_PID=$!
sleep 2

# Get the port from Render environment (default to 10000)
PORT=${PORT:-10000}
echo "Starting noVNC web interface on port $PORT..."

# Start noVNC (websockify)
websockify --web /usr/share/novnc/ \
    $PORT \
    0.0.0.0:5900 \
    --heartbeat 30 > /tmp/novnc.log 2>&1 &

# Alternative: Using novnc_proxy directly
# /usr/share/novnc/utils/novnc_proxy \
#     --vnc localhost:5900 \
#     --listen 0.0.0.0:$PORT \
#     --web /usr/share/novnc/ > /tmp/novnc.log 2>&1 &

echo "=========================================="
echo "Xfce Desktop is ready!"
echo "=========================================="
echo "Access via:"
echo "1. Web browser: https://your-render-url.onrender.com/vnc.html"
echo "2. VNC client: your-render-url.onrender.com:5900 (no password)"
echo "=========================================="

# Keep container running and show logs
tail -f /tmp/xvfb.log /tmp/xfce.log /tmp/x11vnc.log /tmp/novnc.log' > /start.sh
RUN chmod +x /start.sh

# Create alternative simpler script
RUN echo '#!/bin/bash
# Simple startup for Render
export DISPLAY=:99
Xvfb $DISPLAY -screen 0 1280x720x24 -ac &
sleep 2
startxfce4 &
sleep 3
x11vnc -display $DISPLAY -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 &
PORT=${PORT:-10000}
websockify --web /usr/share/novnc/ $PORT 0.0.0.0:5900
tail -f /dev/null' > /start-simple.sh
RUN chmod +x /start-simple.sh

# Create health check endpoint
RUN echo '#!/bin/bash
# Health check script
if pgrep -x "Xvfb" > /dev/null && \
   pgrep -x "xfce4" > /dev/null && \
   pgrep -x "x11vnc" > /dev/null; then
    echo "OK"
    exit 0
else
    echo "NOT OK"
    exit 1
fi' > /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Expose port (Render will map this)
EXPOSE 10000

# Start the service
CMD ["/bin/bash", "/start.sh"]
