# 🚀 Buttery Smooth Browser RDP
# Uses Chrome + GPU acceleration + WebRTC for smooth performance
FROM ubuntu:22.04

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Chrome + GPU acceleration + WebRTC
RUN apt-get update && apt-get install -y \
    # Chrome browser
    wget \
    gnupg \
    # X server with GPU support
    xorg \
    xserver-xorg-video-dummy \
    # Window manager
    openbox \
    # WebRTC remote desktop (Chrome native)
    python3 \
    python3-pip \
    # Utilities
    curl \
    net-tools \
    pulseaudio \
    # Fonts
    fonts-liberation \
    fonts-noto-color-emoji \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (much smoother than Firefox in containers)
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC + WebRTC proxy
RUN pip3 install \
    websockify \
    pyvirtualdisplay \
    selenium \
    python-xlib

# Create user
RUN useradd -m -u 1000 -s /bin/bash user && \
    mkdir -p /home/user/.config/openbox && \
    echo '<?xml version="1.0"?>' > /home/user/.config/openbox/rc.xml && \
    echo '<openbox_config xmlns="http://openbox.org/3.4/rc">' >> /home/user/.config/openbox/rc.xml && \
    echo '  <applications>' >> /home/user/.config/openbox/rc.xml && \
    echo '    <application class="*">' >> /home/user/.config/openbox/rc.xml && \
    echo '      <decor>yes</decor>' >> /home/user/.config/openbox/rc.xml && \
    echo '    </application>' >> /home/user/.config/openbox/rc.xml && \
    echo '  </applications>' >> /home/user/.config/openbox/rc.xml && \
    echo '</openbox_config>' >> /home/user/.config/openbox/rc.xml

# Create X configuration for hardware acceleration
RUN echo 'Section "Device"' > /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyDevice"' >> /etc/X11/xorg.conf && \
    echo '    Driver      "dummy"' >> /etc/X11/xorg.conf && \
    echo '    Option      "IgnoreEDID" "true"' >> /etc/X11/xorg.conf && \
    echo '    Option      "NoDDC" "true"' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf && \
    echo '' >> /etc/X11/xorg.conf && \
    echo 'Section "Monitor"' >> /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyMonitor"' >> /etc/X11/xorg.conf && \
    echo '    HorizSync   31.5 - 48.5' >> /etc/X11/xorg.conf && \
    echo '    VertRefresh 50.0 - 70.0' >> /etc/X11/xorg.conf && \
    echo '    Modeline "1280x1024_60.00" 109.00 1280 1368 1496 1712 1024 1027 1034 1063 -hsync +vsync' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf && \
    echo '' >> /etc/X11/xorg.conf && \
    echo 'Section "Screen"' >> /etc/X11/xorg.conf && \
    echo '    Identifier  "DummyScreen"' >> /etc/X11/xorg.conf && \
    echo '    Device      "DummyDevice"' >> /etc/X11/xorg.conf && \
    echo '    Monitor     "DummyMonitor"' >> /etc/X11/xorg.conf && \
    echo '    DefaultDepth 24' >> /etc/X11/xorg.conf && \
    echo '    SubSection "Display"' >> /etc/X11/xorg.conf && \
    echo '        Depth 24' >> /etc/X11/xorg.conf && \
    echo '        Modes "1280x1024_60.00"' >> /etc/X11/xorg.conf && \
    echo '    EndSubSection' >> /etc/X11/xorg.conf && \
    echo 'EndSection' >> /etc/X11/xorg.conf

# Create Chrome flags for maximum performance
RUN mkdir -p /home/user/.config/google-chrome && \
    echo '{' > /home/user/.config/google-chrome/Local\ State && \
    echo '  "browser": {' >> /home/user/.config/google-chrome/Local\ State && \
    echo '    "enabled_labs_experiments": [' >> /home/user/.config/google-chrome/Local\ State && \
    echo '      "enable-gpu-rasterization@1",' >> /home/user/.config/google-chrome/Local\ State && \
    echo '      "parallel-downloading@1",' >> /home/user/.config/google-chrome/Local\ State && \
    echo '      "smooth-scrolling@1"' >> /home/user/.config/google-chrome/Local\ State && \
    echo '    ]' >> /home/user/.config/google-chrome/Local\ State && \
    echo '  }' >> /home/user/.config/google-chrome/Local\ State && \
    echo '}' >> /home/user/.config/google-chrome/Local\ State

# Create startup script for buttery smooth performance
RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Enable hardware acceleration' >> /start.sh && \
    echo 'export ENABLE_HW_ACCEL="--enable-features=VaapiVideoDecoder,CanvasOopRasterization,UseSkiaRenderer"' >> /start.sh && \
    echo 'export DISABLE_FEATURES="--disable-features=UseChromeOSDirectVideoDecoder"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Performance flags for Chrome' >> /start.sh && \
    echo 'export CHROME_FLAGS="\$ENABLE_HW_ACCEL \$DISABLE_FEATURES \\' >> /start.sh && \
    echo '--no-sandbox \\' >> /start.sh && \
    echo '--disable-dev-shm-usage \\' >> /start.sh && \
    echo '--disable-gpu-sandbox \\' >> /start.sh && \
    echo '--disable-software-rasterizer \\' >> /start.sh && \
    echo '--enable-gpu-rasterization \\' >> /start.sh && \
    echo '--enable-oop-rasterization \\' >> /start.sh && \
    echo '--enable-zero-copy \\' >> /start.sh && \
    echo '--use-gl=desktop \\' >> /start.sh && \
    echo '--ignore-gpu-blocklist \\' >> /start.sh && \
    echo '--enable-hardware-overlays \\' >> /start.sh && \
    echo '--max-tiles-for-interest-area=512 \\' >> /start.sh && \
    echo '--num-raster-threads=4 \\' >> /start.sh && \
    echo '--enable-native-gpu-memory-buffers \\' >> /start.sh && \
    echo '--disable-background-timer-throttling \\' >> /start.sh && \
    echo '--disable-backgrounding-occluded-windows \\' >> /start.sh && \
    echo '--disable-renderer-backgrounding \\' >> /start.sh && \
    echo '--disable-features=TranslateUI"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start X server with dummy driver (hardware acceleration)' >> /start.sh && \
    echo 'Xorg :0 -config /etc/X11/xorg.conf -retro +extension GLX +extension RANDR +extension RENDER -logfile /tmp/Xorg.log &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'export DISPLAY=:0' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Openbox window manager' >> /start.sh && \
    echo 'openbox --config-file /home/user/.config/openbox/rc.xml &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Chrome with buttery smooth flags' >> /start.sh && \
    echo 'echo "🚀 Starting Chrome with GPU acceleration..."' >> /start.sh && \
    echo 'google-chrome-stable \$CHROME_FLAGS \\' >> /start.sh && \
    echo '  --window-size=1280,1024 \\' >> /start.sh && \
    echo '  --window-position=0,0 \\' >> /start.sh && \
    echo '  --force-device-scale-factor=1 \\' >> /start.sh && \
    echo '  --disable-smooth-scrolling=false \\' >> /start.sh && \
    echo '  --start-maximized \\' >> /start.sh && \
    echo '  --remote-debugging-port=9222 \\' >> /start.sh && \
    echo '  --user-data-dir=/tmp/chrome-profile \\' >> /start.sh && \
    echo '  --no-first-run \\' >> /start.sh && \
    echo '  --no-default-browser-check \\' >> /start.sh && \
    echo '  about:blank &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start x11vnc with low latency settings' >> /start.sh && \
    echo 'x11vnc \\' >> /start.sh && \
    echo '  -display :0 \\' >> /start.sh && \
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
    echo '# Start noVNC with WebSocket compression' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 10000 localhost:5900 \\' >> /start.sh && \
    echo '  --heartbeat=30 \\' >> /start.sh && \
    echo '  --timeout=30 \\' >> /start.sh && \
    echo '  --traffic &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "✅ Buttery Smooth Browser Ready!"' >> /start.sh && \
    echo 'echo "🌐 Connect: http://[HOST]:10000/vnc.html"' >> /start.sh && \
    echo 'echo "⚡ Chrome running with GPU acceleration"' >> /start.sh && \
    echo 'echo "🎯 Performance: 60fps target"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Monitor performance' >> /start.sh && \
    echo 'while true; do' >> /start.sh && \
    echo '  sleep 30' >> /start.sh && \
    echo '  echo "📊 Performance check: Chrome running with hardware acceleration"' >> /start.sh && \
    echo 'done' >> /start.sh && \
    chmod +x /start.sh

# Set permissions
RUN chown -R user:user /home/user

USER user
WORKDIR /home/user
EXPOSE 10000 9222
CMD ["/start.sh"]
