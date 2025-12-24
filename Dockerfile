FROM ubuntu:22.04

# 1. Install all necessary packages in one layer
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    sudo \
    dbus-x11 \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# 2. Create a non-root user with explicit UID/GID and add to sudo
RUN useradd -m -u 1000 -s /bin/bash appuser && \
    echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. Set up the xsession file as the correct user
USER appuser
WORKDIR /home/appuser
RUN echo "startxfce4" > .xsession

# 4. Configure xrdp to log to stdout/stderr for Render to capture[citation:9]
USER root
RUN sed -i 's/^\(LogFile=.*\)$/#\1/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^\(LogLevel=.*\)$/#\1/' /etc/xrdp/xrdp.ini && \
    echo "logfile=/dev/stderr" >> /etc/xrdp/xrdp.ini

# 5. Clean up and set the startup command
# The service must bind to 0.0.0.0 and listen on the port Render provides[citation:2]
CMD sudo /usr/sbin/xrdp-sesman && sudo /usr/sbin/xrdp -n
