FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    RESOLUTION=1024x768x16 \
    USER=ubuntu

# Create lightweight user
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    mkdir -p /home/ubuntu/.config

# Install MINIMAL packages only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    websockify \
    xterm \
    htop \
    wget \
    curl \
    sudo \
    dbus-x11 \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create minimal Fluxbox config
RUN mkdir -p /home/ubuntu/.fluxbox && \
    echo '[session] (RootMenu) {}' > /home/ubuntu/.fluxbox/menu && \
    echo '[begin] (Fluxbox)' >> /home/ubuntu/.fluxbox/menu && \
    echo '  [exec] (Terminal) {xterm}' >> /home/ubuntu/.fluxbox/menu && \
    echo '  [exec] (Browser Test) {xterm -e "curl -I https://google.com"}' >> /home/ubuntu/.fluxbox/menu && \
    echo '  [submenu] (System) {}' >> /home/ubuntu/.fluxbox/menu && \
    echo '    [exec] (HTop) {xterm -e htop}' >> /home/ubuntu/.fluxbox/menu && \
    echo '    [exec] (Restart) {pkill fluxbox}' >> /home/ubuntu/.fluxbox/menu && \
    echo '    [exit] (Exit)' >> /home/ubuntu/.fluxbox/menu && \
    echo '  [end]' >> /home/ubuntu/.fluxbox/menu && \
    echo '[end]' >> /home/ubuntu/.fluxbox/menu && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Create startup script
RUN echo '#!/bin/bash
set -e

echo "=== Starting Lightweight Desktop ==="

# Get Render port
PORT=${PORT:-10000}
echo "Using port: $PORT"

# Start Xvfb with minimal settings
echo "Starting Xvfb..."
Xvfb :99 -screen 0 1024x768x16 -ac -nolisten tcp +extension GLX &
sleep 2

# Export display
export DISPLAY=:99

# Start lightweight window manager
echo "Starting Fluxbox..."
sudo -u ubuntu fluxbox &
sleep 2

# Start xterm for testing
echo "Starting terminal..."
sudo -u ubuntu xterm -e "echo Desktop ready!" &
sleep 1

# Start VNC server
echo "Starting VNC server..."
x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 -noxdamage -nowf &
sleep 2

# Start noVNC
echo "Starting noVNC web interface..."
websockify --web /usr/share/novnc/ $PORT 0.0.0.0:5900 --heartbeat 30 &

echo "=== Desktop is ready! ==="
echo "Access URL: https://your-service.onrender.com/vnc.html"

# Keep container alive
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 10000

CMD ["/bin/bash", "/start.sh"]
