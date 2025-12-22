FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99

RUN apt-get update && apt-get install -y \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    websockify \
    xterm \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download and use the proper noVNC version
RUN wget -q https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt && \
    mv /opt/noVNC-1.4.0 /opt/novnc && \
    rm /tmp/novnc.tar.gz

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "=== Starting Desktop Service ==="

# Get port from Render
PORT=${PORT:-10000}
echo "Service will run on port: $PORT"

# Start Xvfb (virtual display)
echo "Starting X virtual framebuffer..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX &
sleep 2

export DISPLAY=:99

# Start window manager
echo "Starting Fluxbox..."
fluxbox &
sleep 2

# Start a terminal
echo "Starting terminal..."
xterm -geometry 80x24+10+10 -e "echo 'Desktop Ready! Close this terminal or keep it open.'" &
sleep 1

# Start VNC server
echo "Starting VNC server..."
x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 &
sleep 2

# Start websockify with proper configuration
echo "Starting noVNC web interface..."
cd /opt/novnc
./utils/novnc_proxy --vnc localhost:5900 --listen 0.0.0.0:$PORT
EOF

RUN chmod +x /start.sh

EXPOSE 10000

CMD ["/bin/bash", "/start.sh"]
