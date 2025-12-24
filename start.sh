#!/bin/bash

# Start as browser user
su - browser -c "
    # Start VNC server
    vncserver :1 -geometry 1024x768 -depth 24 -localhost no &
    
    # Wait for VNC
    sleep 3
    
    # Start noVNC (websockify proxy)
    /home/browser/noVNC/utils/websockify/websockify.py --web /home/browser/noVNC 8080 localhost:5901 &
    
    # Keep container running
    tail -f /dev/null
"
