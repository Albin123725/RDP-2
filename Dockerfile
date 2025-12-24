# 🚀 Direct Web RDP Browser - Connect via Render URL
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL dependencies
RUN apt-get update && apt-get install -y \
    # X server
    xvfb \
    xserver-xorg-video-dummy \
    # VNC
    x11vnc \
    # Window manager
    openbox \
    # Browser
    wget \
    gnupg \
    ca-certificates \
    # Web server
    python3 \
    python3-pip \
    # Fonts
    fonts-liberation \
    # Utilities
    curl \
    net-tools \
    # Clean
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Flask + websockify
RUN pip3 install flask websockify

# Create user
RUN useradd -m -u 1000 -s /bin/bash user

# Copy web interface files
COPY app.py /app.py
COPY index.html /index.html

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Xvfb' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension RANDR -nolisten tcp &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Openbox' >> /start.sh && \
    echo 'openbox &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Chrome' >> /start.sh && \
    echo 'google-chrome-stable --no-sandbox --disable-dev-shm-usage --start-maximized &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server' >> /start.sh && \
    echo 'x11vnc -display :99 -forever -shared -nopw -listen 127.0.0.1 -rfbport 5900 -noxdamage &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start websockify proxy' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 6080 localhost:5900 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Flask web server' >> /start.sh && \
    echo 'python3 /app.py &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "✅ RDP Browser Ready!"' >> /start.sh && \
    echo 'echo "🌐 Connect directly to your Render URL"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

USER user
EXPOSE 10000
CMD ["/start.sh"]
