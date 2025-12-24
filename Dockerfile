# Use Ubuntu minimal
FROM ubuntu:22.04

# Set non-interactive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal packages
RUN apt-get update && apt-get install -y \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    
    # Minimal desktop
    openbox \
    
    # Web browser
    firefox \
    
    # noVNC for web access
    websockify \
    python3 \
    python3-numpy \
    
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash browser && \
    echo "browser:password" | chpasswd

# Setup VNC
USER browser
WORKDIR /home/browser

# Create VNC config
RUN mkdir -p ~/.vnc && \
    echo "password" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd && \
    echo "openbox &" > ~/.vnc/xstartup && \
    echo "firefox --kiosk https://www.google.com --width=1024 --height=768" >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Download noVNC
RUN git clone https://github.com/novnc/noVNC.git /home/browser/noVNC && \
    git clone https://github.com/novnc/websockify /home/browser/noVNC/utils/websockify

# Expose port (Render free tier only allows one port)
EXPOSE 8080

# Startup script
USER root
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
