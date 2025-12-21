#!/bin/bash

echo "=== Setting up XFCE Desktop ==="

# Set environment variables
export USER=root
export HOME=/root
export DISPLAY=:1
export LANG=en_US.UTF-8

# Create directories
mkdir -p /tmp/.X11-unix /var/run/dbus
chmod 1777 /tmp/.X11-unix

# Start DBus
echo "Starting DBus..."
dbus-daemon --system --fork

# Clean up previous sessions
echo "Cleaning up..."
vncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Start VNC with verbose output
echo "Starting VNC server..."
vncserver :1 \
    -geometry 1280x720 \
    -depth 24 \
    -localhost no \
    -alwaysshared \
    -SecurityTypes VncAuth \
    -Log *:stdout:100

echo "VNC should be running on :1 (port 5901)"
echo "Password: Albin4242"

# Wait for VNC to start
sleep 2

# Check if VNC is running
if ! pgrep -x Xvnc > /dev/null; then
    echo "ERROR: VNC server failed to start!"
    echo "Trying alternative method..."
    
    # Alternative: Start Xvnc directly
    Xvnc :1 -geometry 1280x720 -depth 24 -rfbauth /root/.vnc/passwd \
          -localhost no -SecurityTypes VncAuth &
    sleep 2
fi

echo "Starting noVNC web interface..."
echo "Access at: https://${RENDER_EXTERNAL_HOSTNAME:-localhost}:8900/vnc.html"

# Start websockify
exec websockify --web=/usr/share/novnc 0.0.0.0:8900 localhost:5901
