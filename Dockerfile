# 🚀 Buttery Smooth Browser - Render Compatible
# FIXED VERSION: Package errors resolved
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL dependencies in one layer - FIXED PACKAGE LIST
RUN apt-get update && apt-get install -y \
    # X server with console access
    xvfb \
    xserver-xorg-video-dummy \
    xserver-xorg-input-evdev \
    # VNC server
    x11vnc \
    # Window manager
    openbox \
    obconf \
    # Browser (Chrome for smooth performance)
    wget \
    gnupg \
    ca-certificates \
    # Python for websockify
    python3 \
    python3-pip \
    # Fonts
    fonts-liberation \
    fonts-noto-color-emoji \
    # Utilities
    curl \
    net-tools \
    dbus-x11 \
    # Additional dependencies for Chrome
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    # Clean
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install websockify (noVNC)
RUN pip3 install websockify

# Create non-root user (required for X server on Render)
RUN useradd -m -u 1000 -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/user/.config/openbox

# Create Xorg config for dummy driver
RUN mkdir -p /etc/X11 && \
    echo 'Section "Device"' > /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyDevice"' >> /etc/X11/xorg.conf && \
    echo '    Driver      "dummy"' >> /etc/X11/xorg.conf && \
    echo '    Option      "IgnoreEDID" "true"' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf && \
    echo '' >> /etc/X11/xorg.conf && \
    echo 'Section "Monitor"' >> /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyMonitor"' >> /etc/X11/xorg.conf && \
    echo '    HorizSync   31.5 - 48.5' >> /etc/X11/xorg.conf && \
    echo '    VertRefresh 50.0 - 70.0' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf && \
    echo '' >> /etc/X11/xorg.conf && \
    echo 'Section "Screen"' >> /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyScreen"' >> /etc/X11/xorg.conf && \
    echo '    Device      "DummyDevice"' >> /etc/X11/xorg.conf && \
    echo '    Monitor     "DummyMonitor"' >> /etc/X11/xorg.conf && \
    echo '    DefaultDepth 24' >> /etc/X11/xorg.conf && \
    echo '    SubSection "Display"' >> /etc/X11/xorg.conf && \
    echo '        Depth 24' >> /etc/X11/xorg.conf && \
    echo '        Modes "1280x1024"' >> /etc/X11/xorg.conf && \
    echo '    EndSubSection' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Create X authority file' >> /start.sh && \
    echo 'touch /tmp/.Xauthority' >> /start.sh && \
    echo 'chmod 600 /tmp/.Xauthority' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Xvfb as user (bypasses Xorg.wrap restriction)' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension RANDR +extension GLX +extension MIT-SHM -nolisten tcp &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo 'export XAUTHORITY=/tmp/.Xauthority' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait for X server' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Openbox' >> /start.sh && \
    echo 'openbox --sm-disable --config-file /etc/xdg/openbox/rc.xml &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Chrome with GPU acceleration flags' >> /start.sh && \
    echo 'google-chrome-stable \\' >> /start.sh && \
    echo '  --no-sandbox \\' >> /start.sh && \
    echo '  --disable-dev-shm-usage \\' >> /start.sh && \
    echo '  --disable-gpu-sandbox \\' >> /start.sh && \
    echo '  --enable-gpu-rasterization \\' >> /start.sh && \
    echo '  --enable-oop-rasterization \\' >> /start.sh && \
    echo '  --use-gl=egl \\' >> /start.sh && \
    echo '  --ignore-gpu-blocklist \\' >> /start.sh && \
    echo '  --num-raster-threads=4 \\' >> /start.sh && \
    echo '  --enable-zero-copy \\' >> /start.sh && \
    echo '  --disable-background-timer-throttling \\' >> /start.sh && \
    echo '  --disable-renderer-backgrounding \\' >> /start.sh && \
    echo '  --window-size=1280,1024 \\' >> /start.sh && \
    echo '  --window-position=0,0 \\' >> /start.sh && \
    echo '  --force-device-scale-factor=1 \\' >> /start.sh && \
    echo '  --start-maximized \\' >> /start.sh && \
    echo '  --remote-debugging-port=9222 \\' >> /start.sh && \
    echo '  --user-data-dir=/tmp/chrome-profile \\' >> /start.sh && \
    echo '  --no-first-run \\' >> /start.sh && \
    echo '  --no-default-browser-check \\' >> /start.sh && \
    echo '  about:blank &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start x11vnc' >> /start.sh && \
    echo 'x11vnc \\' >> /start.sh && \
    echo '  -display :99 \\' >> /start.sh && \
    echo '  -forever \\' >> /start.sh && \
    echo '  -shared \\' >> /start.sh && \
    echo '  -nopw \\' >> /start.sh && \
    echo '  -listen 0.0.0.0 \\' >> /start.sh && \
    echo '  -rfbport 5900 \\' >> /start.sh && \
    echo '  -noxdamage \\' >> /start.sh && \
    echo '  -xkb \\' >> /start.sh && \
    echo '  -threads \\' >> /start.sh && \
    echo '  -defer 1 \\' >> /start.sh && \
    echo '  -wait 1 \\' >> /start.sh && \
    echo '  -notruecolor \\' >> /start.sh && \
    echo '  -cursor arrow &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Create simple web directory for noVNC' >> /start.sh && \
    echo 'mkdir -p /tmp/novnc' >> /start.sh && \
    echo 'echo "<html><body><h1>VNC Server Ready</h1><p>Connect via VNC client to port 5900</p></body></html>" > /tmp/novnc/index.html' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start websockify on port 10000' >> /start.sh && \
    echo 'websockify --web /tmp/novnc 10000 localhost:5900 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "✅ Buttery Smooth Browser Ready!"' >> /start.sh && \
    echo 'echo "🌐 Web Interface: http://[HOST]:10000/vnc.html"' >> /start.sh && \
    echo 'echo "🔗 Direct VNC: port 5900 (no password)"' >> /start.sh && \
    echo 'echo "⚡ Chrome running with GPU acceleration"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

USER user
WORKDIR /home/user
EXPOSE 10000
CMD ["/start.sh"]
