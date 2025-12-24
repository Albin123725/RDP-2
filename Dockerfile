FROM ubuntu:22.04

# 1. Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# 2. Pre-configure keyboard settings for English US
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/layoutcode string us" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/variantcode string" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/modelcode string pc105" | debconf-set-selections

# 3. Install all packages without interactive prompts
RUN apt-get update && apt-get install -y \
    tzdata \
    keyboard-configuration \
    locales \
    xfce4 \
    xfce4-goodies \
    xrdp \
    sudo \
    dbus-x11 \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# 4. Set locale and timezone
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    locale-gen en_US.UTF-8

# 5. Create user and setup
RUN useradd -m -u 1000 -s /bin/bash appuser && \
    echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER appuser
WORKDIR /home/appuser
RUN echo "startxfce4" > .xsession

USER root
RUN sed -i 's/^\(LogFile=.*\)$/#\1/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^\(LogLevel=.*\)$/#\1/' /etc/xrdp/xrdp.ini && \
    echo "logfile=/dev/stderr" >> /etc/xrdp/xrdp.ini

CMD sudo /usr/sbin/xrdp-sesman && sudo /usr/sbin/xrdp -n
