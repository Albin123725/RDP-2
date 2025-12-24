#!/usr/bin/env python3
"""
🚀 ULTRA-MINIMAL RDP BROWSER - ALPINE COMPATIBLE
Single-app RDP with only browser
"""

import os
import sys
import time
import json
import signal
import logging
from flask import Flask, render_template_string, jsonify, request

# Add virtual environment path for Alpine
venv_path = '/app/venv/lib/python3.11/site-packages'
if os.path.exists(venv_path):
    sys.path.insert(0, venv_path)

app = Flask(__name__)

# ==================== CONFIGURATION ====================
CONFIG = {
    'target_url': 'https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter',
    'resolution': '1024x768',
    'vnc_port': 5901,
    'web_port': 6081,
    'control_port': int(os.environ.get('PORT', 10000)),
    'host': '0.0.0.0',
    'debug': False
}

# ==================== LOGGING ====================
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# ==================== STATUS TRACKING ====================
class BrowserStatus:
    def __init__(self):
        self.start_time = time.time()
        self.rdp_running = True  # Always running in this setup
        self.last_update = time.time()
    
    def get_uptime(self):
        return time.time() - self.start_time
    
    def get_status(self):
        return {
            'status': 'running',
            'rdp_running': self.rdp_running,
            'uptime': self.get_uptime(),
            'uptime_hours': round(self.get_uptime() / 3600, 1),
            'target_url': CONFIG['target_url'],
            'vnc_port': CONFIG['vnc_port'],
            'web_port': CONFIG['web_port'],
            'resolution': CONFIG['resolution'],
            'memory_mb': self.estimate_memory()
        }
    
    def estimate_memory(self):
        """Estimate memory usage"""
        try:
            import psutil
            return round(psutil.Process().memory_info().rss / 1024 / 1024, 1)
        except:
            # Fallback estimation
            return 150.0

status = BrowserStatus()

# ==================== HTML TEMPLATE ====================
INDEX_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Ultra-Minimal RDP Browser</title>
    <style>
        :root {
            --primary: #3b82f6;
            --primary-dark: #1d4ed8;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, var(--bg-dark) 0%, #1e293b 100%);
            color: white;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        h1 {
            text-align: center;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 2.5em;
        }
        
        .subtitle {
            text-align: center;
            color: #94a3b8;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.08);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            background: linear-gradient(135deg, var(--success) 0%, #059669 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #94a3b8;
            font-size: 0.9em;
        }
        
        .controls {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            justify-content: center;
            margin: 30px 0;
        }
        
        .btn {
            padding: 15px 30px;
            background: linear-gradient(135deg, var(--color) 0%, var(--color-dark) 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            font-size: 16px;
            transition: all 0.3s;
            min-width: 200px;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        
        .btn-primary { --color: #3b82f6; --color-dark: #1d4ed8; }
        .btn-success { --color: #10b981; --color-dark: #059669; }
        .btn-warning { --color: #f59e0b; --color-dark: #d97706; }
        
        .url-box {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            font-family: monospace;
            word-break: break-all;
            border-left: 4px solid var(--primary);
        }
        
        .connection-box {
            background: rgba(59, 130, 246, 0.1);
            border-left: 4px solid var(--primary);
            padding: 20px;
            border-radius: 0 10px 10px 0;
            margin: 20px 0;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .info-card {
            background: rgba(255, 255, 255, 0.05);
            padding: 15px;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        @media (max-width: 600px) {
            .container { padding: 15px; }
            .btn { min-width: 100%; }
            .stats-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Ultra-Minimal RDP Browser</h1>
        <div class="subtitle">Single-app RDP • Only Browser • Low Memory</div>
        
        <!-- Stats -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">{{memory_mb}} MB</div>
                <div class="stat-label">Memory Usage</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{{uptime_hours}}h</div>
                <div class="stat-label">Uptime</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">✅</div>
                <div class="stat-label">Status: Running</div>
            </div>
        </div>
        
        <!-- Target URL -->
        <div class="url-box">
            <strong>🎯 Target Website:</strong><br>
            {{target_url}}
        </div>
        
        <!-- Connection Info -->
        <div class="connection-box">
            <h3>📡 Connection Methods</h3>
            
            <div class="info-grid">
                <div class="info-card">
                    <strong>🌐 Web VNC</strong><br>
                    <small>Browser-based access</small>
                    <div style="margin-top: 8px; font-family: monospace;">
                        {{web_vnc_url}}
                    </div>
                </div>
                
                <div class="info-card">
                    <strong>🔗 Direct VNC</strong><br>
                    <small>VNC client connection</small>
                    <div style="margin-top: 8px; font-family: monospace;">
                        {{hostname}}:{{vnc_port}}
                    </div>
                </div>
                
                <div class="info-card">
                    <strong>⚙️ Settings</strong><br>
                    <small>Optimized for low memory</small>
                    <div style="margin-top: 8px;">
                        {{resolution}} • No Password
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Control Buttons -->
        <div class="controls">
            <button class="btn btn-primary" onclick="openWebVNC()">
                <span>🌐</span> Open Web VNC
            </button>
            
            <button class="btn btn-success" onclick="openDirectLink()">
                <span>🚀</span> Open Direct Link
            </button>
            
            <button class="btn btn-warning" onclick="refreshStatus()">
                <span>🔄</span> Refresh Status
            </button>
        </div>
        
        <!-- Quick Guide -->
        <div style="margin-top: 30px; padding: 15px; background: rgba(255,255,255,0.05); border-radius: 10px;">
            <h3>📋 Quick Start</h3>
            <ol style="margin: 10px 0 10px 20px; line-height: 1.8;">
                <li>Click <strong>"Open Web VNC"</strong> for browser access</li>
                <li>Browser is pre-loaded with the target website</li>
                <li>No login required - connect immediately</li>
                <li>Status auto-refreshes every 30 seconds</li>
            </ol>
        </div>
        
        <!-- Footer -->
        <div style="margin-top: 30px; text-align: center; color: #94a3b8; font-size: 0.9em;">
            <p>Ultra-Minimal RDP Browser • Alpine Linux • ~150MB memory</p>
        </div>
    </div>

    <script>
        let refreshCountdown = 30;
        
        function updateTimer() {
            const timer = document.getElementById('refreshTimer');
            if (timer) {
                timer.textContent = `Refreshing in ${refreshCountdown}s`;
                refreshCountdown--;
                
                if (refreshCountdown <= 0) {
                    refreshCountdown = 30;
                    window.location.reload();
                }
            }
        }
        
        // Start timer
        setInterval(updateTimer, 1000);
        
        function openWebVNC() {
            window.open('{{web_vnc_url}}', '_blank', 'noopener,noreferrer');
        }
        
        function openDirectLink() {
            window.open('{{target_url}}', '_blank', 'noopener,noreferrer');
        }
        
        function refreshStatus() {
            window.location.reload();
        }
        
        // Auto-refresh every 30 seconds
        setTimeout(() => {
            window.location.reload();
        }, 30000);
    </script>
</body>
</html>
'''

# ==================== FLASK ROUTES ====================
@app.route('/')
def index():
    """Main control panel"""
    hostname = os.environ.get('RENDER_EXTERNAL_HOSTNAME', 'localhost')
    
    status_data = status.get_status()
    
    return render_template_string(
        INDEX_HTML,
        memory_mb=status_data['memory_mb'],
        uptime_hours=status_data['uptime_hours'],
        target_url=CONFIG['target_url'],
        web_vnc_url=f"http://{hostname}:{CONFIG['web_port']}/vnc.html",
        hostname=hostname,
        vnc_port=CONFIG['vnc_port'],
        resolution=CONFIG['resolution']
    )

@app.route('/api/status')
def api_status():
    """JSON status endpoint"""
    return jsonify(status.get_status())

@app.route('/health')
def health():
    """Health check for Render"""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'ultra-minimal-rdp-browser',
        'version': '1.0'
    }), 200

@app.route('/ping')
def ping():
    """Simple ping endpoint"""
    return 'pong', 200

# ==================== STARTUP ====================
def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Shutting down...")
    sys.exit(0)

def main():
    """Main entry point"""
    # Setup signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Log startup
    logger.info("🚀 Starting Ultra-Minimal RDP Browser")
    logger.info(f"Control Panel: http://0.0.0.0:{CONFIG['control_port']}")
    logger.info(f"Web VNC: http://localhost:{CONFIG['web_port']}/vnc.html")
    logger.info(f"Direct VNC: localhost:{CONFIG['vnc_port']} (no password)")
    logger.info(f"Target URL: {CONFIG['target_url']}")
    
    # Start Flask app
    app.run(
        host=CONFIG['host'],
        port=CONFIG['control_port'],
        debug=CONFIG['debug'],
        threaded=True
    )

if __name__ == '__main__':
    main()
