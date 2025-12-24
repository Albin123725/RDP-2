# Dockerfile approach (might work on paid plans)
FROM ubuntu:22.04

# Install minimal GUI
RUN apt update && apt install -y \
    xfce4 \
    xrdp \
    firefox \
    --no-install-recommends

# Set up RDP
RUN echo "startxfce4" > /home/app/.xsession
EXPOSE 3389

CMD ["xrdp", "--nodaemon"]
