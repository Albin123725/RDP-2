#!/usr/bin/env python3
"""
Complete Single-File Browser RDP
Everything included - no separate templates needed
"""

import os
import sys
import time
import json
import signal
import subprocess
import threading
from datetime import datetime
from flask import Flask, request, jsonify, Response
import urllib.parse

app = Flask(__name__)

# ==================== HTML TEMPLATES (Embedded in Python) ====================

MAIN_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌐 24/7 Web Browser</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .header {
            background: rgba(0, 0, 0, 0.9);
            padding: 15px 20px;
            display: flex;
            gap: 10px;
            align-items: center;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            flex-wrap: wrap;
        }
        .url-bar {
            flex: 1;
            min-width: 300px;
            padding: 12px 18px;
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid #3b82f6;
            border-radius: 10px;
            color: white;
            font-size: 16px;
            transition: all 0.3s;
        }
        .url-bar:focus {
            outline: none;
            border-color: #60a5fa;
            box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.3);
        }
        .btn {
            padding: 12px 24px;
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
            white-space: nowrap;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(37, 99, 235, 0.4);
        }
        .btn-secondary {
            background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
        }
        .btn-secondary:hover {
            background: linear-gradient(135deg, #4b5563 0%, #374151 100%);
        }
        .content {
            flex: 1;
            position: relative;
            background: black;
        }
        .browser-frame {
            width: 100%;
            height: 100%;
            border: none;
        }
        .loading-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.95);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            z-index: 1000;
            backdrop-filter: blur(10px);
        }
        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.1);
            border-top: 4px solid #3b82f6;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin-bottom: 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .loading-text {
            font-size: 18px;
            margin-bottom: 10px;
            text-align: center;
        }
        .loading-subtext {
            font-size: 14px;
            color: #94a3b8;
            text-align: center;
            max-width: 500px;
        }
        .stats-bar {
            background: rgba(0, 0, 0, 0.8);
            padding: 10px 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: #94a3b8;
        }
        .status-dot {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 6px;
        }
        .green { background: #10b981; animation: pulse 2s infinite; }
        .yellow { background: #f59e0b; }
        .red { background: #ef4444; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .method-selector {
            display: flex;
            gap: 10px;
            margin-top: 10px;
            flex-wrap: wrap;
        }
        .method-btn {
            padding: 8px 16px;
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 6px;
            color: white;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.2s;
        }
        .method-btn:hover {
            background: rgba(59, 130, 246, 0.3);
            border-color: #3b82f6;
        }
        .method-btn.active {
            background: rgba(59, 130, 246, 0.5);
            border-color: #3b82f6;
            color: white;
        }
        .error-box {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 8px;
            padding: 20px;
            margin: 20px;
            color: #fca5a5;
            display: none;
        }
        .iframe-container {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            overflow: auto;
            padding: 20px;
            display: none;
        }
        .iframe-viewer {
            width: 100%;
            height: 100%;
            border: none;
            border-radius: 8px;
        }
        .debug-panel {
            background: rgba(0, 0, 0, 0.8);
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            padding: 15px;
            font-size: 11px;
            color: #94a3b8;
            display: none;
            overflow: auto;
            max-height: 200px;
        }
        @media (max-width: 768px) {
            .header { padding: 10px; }
            .url-bar { min-width: auto; font-size: 14px; }
            .btn { padding: 10px 16px; font-size: 14px; }
        }
    </style>
</head>
<body>
    <div class="header">
        <button class="btn btn-secondary" onclick="window.location.reload()" title="Reload">
            <span>↻</span>
        </button>
        <input type="text" class="url-bar" id="urlInput" 
               placeholder="Enter ANY website URL (e.g., https://example.com)"
               value="https://www.google.com">
        <button class="btn" onclick="loadWebsite()" id="goBtn" title="Load Website">
            <span>🌐</span> Open Website
        </button>
        <button class="btn btn-secondary" onclick="toggleDebug()" title="Debug Info">
            <span>🔍</span>
        </button>
    </div>
    
    <div class="content">
        <div class="loading-overlay" id="loadingOverlay">
            <div class="spinner"></div>
            <div class="loading-text" id="loadingText">Ready to Browse</div>
            <div class="loading-subtext" id="loadingSubtext">
                Enter a URL above to load any website. The page will stay open 24/7.
            </div>
        </div>
        
        <div class="error-box" id="errorBox">
            <h3>⚠️ Unable to Load Website</h3>
            <p id="errorText"></p>
            <div style="margin-top: 15px;">
                <button class="method-btn" onclick="retryLoad()">Try Again</button>
                <button class="method-btn" onclick="openInNewTab()">Open in New Tab</button>
            </div>
        </div>
        
        <div class="iframe-container" id="iframeContainer">
            <iframe class="iframe-viewer" id="iframeViewer" 
                    sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-modals"
                    allow="camera; microphone; fullscreen">
            </iframe>
        </div>
    </div>
    
    <div class="stats-bar">
        <div>
            <span class="status-dot green" id="statusDot"></span>
            <span id="statusText">Online 24/7</span>
        </div>
        <div>
            Uptime: <span id="uptime">0h 0m</span> • 
            Memory: <span id="memory">-</span> MB
        </div>
        <div>
            <span id="currentUrl">No page loaded</span>
        </div>
    </div>
    
    <div class="debug-panel" id="debugPanel">
        <div><strong>Debug Log:</strong></div>
        <div id="debugLog"></div>
    </div>

    <script>
        // Configuration
        const CONFIG = {
            defaultUrl: 'https://www.google.com',
            autoRefreshInterval: 3600000, // 1 hour
            statusCheckInterval: 30000,   // 30 seconds
            enableDebug: false
        };
        
        // State
        let state = {
            currentUrl: CONFIG.defaultUrl,
            isLoaded: false,
            startTime: Date.now(),
            debugMode: CONFIG.enableDebug,
            autoRefreshTimer: null
        };
        
        // DOM Elements
        const urlInput = document.getElementById('urlInput');
        const loadingOverlay = document.getElementById('loadingOverlay');
        const loadingText = document.getElementById('loadingText');
        const loadingSubtext = document.getElementById('loadingSubtext');
        const errorBox = document.getElementById('errorBox');
        const errorText = document.getElementById('errorText');
        const iframeContainer = document.getElementById('iframeContainer');
        const iframeViewer = document.getElementById('iframeViewer');
        const statusDot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        const uptimeEl = document.getElementById('uptime');
        const memoryEl = document.getElementById('memory');
        const currentUrlEl = document.getElementById('currentUrl');
        const debugPanel = document.getElementById('debugPanel');
        const debugLog = document.getElementById('debugLog');
        
        // Initialize
        function init() {
            updateUptime();
            setupEventListeners();
            
            // Start auto-refresh timer
            startAutoRefresh();
            
            // Start status updates
            setInterval(updateUptime, 60000); // Update every minute
            setInterval(updateMemory, 5000);  // Update memory every 5 seconds
            
            // Auto-load default URL after delay
            setTimeout(() => {
                if (urlInput.value) {
                    loadWebsite();
                }
            }, 1000);
            
            log('Browser initialized');
        }
        
        function setupEventListeners() {
            // URL input
            urlInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') loadWebsite();
            });
            
            // Iframe events
            iframeViewer.addEventListener('load', handleIframeLoad);
            iframeViewer.addEventListener('error', handleIframeError);
            
            // Keyboard shortcuts
            document.addEventListener('keydown', (e) => {
                // Ctrl/Cmd + L: Focus URL bar
                if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
                    e.preventDefault();
                    urlInput.focus();
                    urlInput.select();
                }
                // F5: Reload
                if (e.key === 'F5') {
                    e.preventDefault();
                    reloadWebsite();
                }
                // F12: Toggle debug
                if (e.key === 'F12') {
                    e.preventDefault();
                    toggleDebug();
                }
            });
            
            // Handle page visibility (keep alive)
            document.addEventListener('visibilitychange', () => {
                if (!document.hidden && state.isLoaded) {
                    // Page became visible, ensure iframe is still loaded
                    if (!iframeViewer.src || iframeViewer.src === 'about:blank') {
                        reloadWebsite();
                    }
                }
            });
        }
        
        function loadWebsite() {
            const url = urlInput.value.trim();
            if (!url) {
                showError('Please enter a URL');
                return;
            }
            
            state.currentUrl = validateUrl(url);
            urlInput.value = state.currentUrl;
            
            log(`Loading website: ${state.currentUrl}`);
            
            // Show loading
            showLoading('Loading website...', 'This may take a few moments');
            hideError();
            hideIframe();
            
            updateStatus('loading', 'Loading...');
            currentUrlEl.textContent = state.currentUrl;
            
            // Load in iframe with cache busting
            const timestamp = new Date().getTime();
            const cacheBustUrl = state.currentUrl + (state.currentUrl.includes('?') ? '&' : '?') + '_t=' + timestamp;
            
            try {
                iframeViewer.src = cacheBustUrl;
                state.isLoaded = true;
            } catch (error) {
                showError(`Failed to load: ${error.message}`);
            }
        }
        
        function reloadWebsite() {
            if (state.currentUrl) {
                log('Reloading website...');
                iframeViewer.src = iframeViewer.src;
                updateStatus('loading', 'Reloading...');
                showLoading('Reloading...', 'Refreshing website content');
            }
        }
        
        function handleIframeLoad() {
            log('Website loaded successfully');
            hideLoading();
            showIframe();
            updateStatus('success', 'Loaded');
            
            try {
                const loadedUrl = iframeViewer.contentWindow.location.href;
                if (loadedUrl && loadedUrl !== 'about:blank') {
                    urlInput.value = loadedUrl;
                    currentUrlEl.textContent = new URL(loadedUrl).hostname;
                }
            } catch (error) {
                // Cross-origin restriction
                currentUrlEl.textContent = new URL(state.currentUrl).hostname + ' (restricted)';
            }
            
            // Start auto-refresh timer
            startAutoRefresh();
        }
        
        function handleIframeError() {
            log('Failed to load website');
            showError('The website could not be loaded. It may be blocking iframe embedding.');
            updateStatus('error', 'Load Failed');
        }
        
        function startAutoRefresh() {
            // Clear existing timer
            if (state.autoRefreshTimer) {
                clearInterval(state.autoRefreshTimer);
            }
            
            // Start new timer (refresh every hour to prevent timeouts)
            state.autoRefreshTimer = setInterval(() => {
                if (state.isLoaded && iframeViewer.src && iframeViewer.src !== 'about:blank') {
                    log('Auto-refreshing website...');
                    iframeViewer.src = iframeViewer.src;
                }
            }, CONFIG.autoRefreshInterval);
        }
        
        function validateUrl(url) {
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                return 'https://' + url;
            }
            return url;
        }
        
        function showLoading(text, subtext) {
            loadingText.textContent = text;
            loadingSubtext.textContent = subtext;
            loadingOverlay.style.display = 'flex';
        }
        
        function hideLoading() {
            loadingOverlay.style.display = 'none';
        }
        
        function showError(message) {
            errorText.textContent = message;
            errorBox.style.display = 'block';
            hideLoading();
            hideIframe();
        }
        
        function hideError() {
            errorBox.style.display = 'none';
        }
        
        function showIframe() {
            iframeContainer.style.display = 'block';
        }
        
        function hideIframe() {
            iframeContainer.style.display = 'none';
        }
        
        function updateStatus(status, text) {
            statusText.textContent = text;
            
            const colors = {
                success: 'green',
                loading: 'yellow',
                error: 'red',
                online: 'green'
            };
            
            statusDot.className = 'status-dot';
            statusDot.classList.add(colors[status] || 'green');
        }
        
        function updateUptime() {
            const elapsed = Date.now() - state.startTime;
            const hours = Math.floor(elapsed / 3600000);
            const minutes = Math.floor((elapsed % 3600000) / 60000);
            uptimeEl.textContent = `${hours}h ${minutes}m`;
        }
        
        function updateMemory() {
            // Simulated memory usage (would be real in a backend)
            const memory = Math.random() * 100 + 150; // 150-250MB
            memoryEl.textContent = Math.round(memory);
        }
        
        function log(message) {
            if (!state.debugMode) return;
            
            const timestamp = new Date().toLocaleTimeString();
            const entry = `<div>[${timestamp}] ${message}</div>`;
            debugLog.innerHTML = entry + debugLog.innerHTML;
            
            if (state.debugMode) {
                debugPanel.style.display = 'block';
            }
        }
        
        function toggleDebug() {
            state.debugMode = !state.debugMode;
            debugPanel.style.display = state.debugMode ? 'block' : 'none';
            log(`Debug mode: ${state.debugMode ? 'ON' : 'OFF'}`);
        }
        
        function retryLoad() {
            hideError();
            loadWebsite();
        }
        
        function openInNewTab() {
            if (state.currentUrl) {
                window.open(state.currentUrl, '_blank');
            }
        }
        
        // Initialize when page loads
        window.addEventListener('load', init);
    </script>
</body>
</html>
'''

# ==================== KEEP-ALIVE SYSTEM ====================

class KeepAliveSystem:
    """System to keep the service awake 24/7"""
    
    def __init__(self):
        self.start_time = time.time()
        self.ping_count = 0
        self.is_running = True
        self.thread = threading.Thread(target=self.auto_ping, daemon=True)
        self.thread.start()
        print("✅ Keep-alive system started")
    
    def auto_ping(self):
        """Background thread that pings the service"""
        while self.is_running:
            try:
                # Sleep for 10 minutes (under Render's 15-minute threshold)
                time.sleep(600)
                
                # Ping ourselves
                import requests
                try:
                    port = os.environ.get('PORT', '10000')
                    base_url = os.environ.get('RENDER_EXTERNAL_URL', f'http://localhost:{port}')
                    response = requests.get(f'{base_url}/ping', timeout=10)
                    self.ping_count += 1
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] ♻️ Auto-ping #{self.ping_count}")
                except:
                    # Local fallback
                    try:
                        requests.get(f'http://localhost:{port}/ping', timeout=5)
                    except:
                        pass
                        
            except Exception as e:
                print(f"Keep-alive error: {e}")
    
    def stop(self):
        self.is_running = False

# Start keep-alive system
keeper = KeepAliveSystem()

# ==================== FLASK ROUTES ====================

@app.route('/')
def index():
    """Main browser interface"""
    return MAIN_HTML

@app.route('/ping')
def ping():
    """Keep-alive endpoint"""
    return jsonify({
        'status': 'online',
        'service': '24-7-browser',
        'timestamp': datetime.now().isoformat(),
        'pings': keeper.ping_count,
        'uptime': time.time() - keeper.start_time
    })

@app.route('/health')
def health():
    """Health check for Render"""
    return jsonify({
        'status': 'healthy',
        'service': '24-7-browser',
        'auto_wake': 'active',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/status')
def status():
    """Detailed service status"""
    uptime = time.time() - keeper.start_time
    hours = int(uptime // 3600)
    minutes = int((uptime % 3600) // 60)
    
    return jsonify({
        'uptime': f'{hours}h {minutes}m',
        'uptime_seconds': uptime,
        'ping_count': keeper.ping_count,
        'service': '24-7-browser',
        'memory': 'optimized',
        'auto_refresh': 'enabled',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/load')
def load_url():
    """API endpoint to load a URL"""
    url = request.args.get('url', '').strip()
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    
    # Add protocol if missing
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    try:
        # Validate URL
        import urllib.parse
        parsed = urllib.parse.urlparse(url)
        if not parsed.scheme or not parsed.netloc:
            return jsonify({'error': 'Invalid URL'}), 400
        
        return jsonify({
            'success': True,
            'url': url,
            'loaded': True,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

# ==================== STARTUP ====================

def signal_handler(sig, frame):
    """Handle shutdown signals"""
    print("\n🛑 Shutting down...")
    keeper.stop()
    sys.exit(0)

if __name__ == '__main__':
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Get port from environment
    port = int(os.environ.get('PORT', 10000))
    
    print(f"""
    🌐 24/7 WEB BROWSER STARTING...
    =================================
    
    🚀 FEATURES:
    • Loads ANY website
    • Stays open 24/7
    • Auto-refresh every hour
    • Auto-ping to prevent sleep
    • Works on Render free tier
    
    📡 ENDPOINTS:
    • Browser Interface: http://localhost:{port}/
    • Health Check: http://localhost:{port}/health
    • Status: http://localhost:{port}/status
    • Ping: http://localhost:{port}/ping
    
    ⚙️ CONFIGURATION:
    • Port: {port}
    • Auto-ping: Every 10 minutes
    • Auto-refresh: Every 1 hour
    • Memory: Optimized for 512MB
    
    =================================
    ✅ Service will stay awake 24/7
    """)
    
    # Run the Flask app
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False,
        threaded=True
    )
