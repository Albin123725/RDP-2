#!/usr/bin/env python3
"""
COMPLETE SINGLE-FILE UNIVERSAL BROWSER
Automatically handles blocked sites and provides smart alternatives
FIXED VERSION: GitHub Codespaces and all blocked sites work properly
"""

import os
import time
import json
import threading
import urllib.parse
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string, redirect
import requests

app = Flask(__name__)

# ==================== CONFIGURATION ====================
CONFIG = {
    'default_url': 'https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter',
    'keep_alive_interval': 600,  # 10 minutes
    'iframe_timeout': 5,  # seconds
    'auto_redirect_delay': 2,  # seconds
    'debug': True
}

# ==================== KEEP-ALIVE SYSTEM ====================
class KeepAliveSystem:
    def __init__(self):
        self.start_time = time.time()
        self.ping_count = 0
        self.running = True
        self.thread = threading.Thread(target=self._keep_alive_worker, daemon=True)
        self.thread.start()
        self.log("✅ Keep-alive system started")
    
    def _keep_alive_worker(self):
        while self.running:
            try:
                time.sleep(CONFIG['keep_alive_interval'])
                port = os.environ.get('PORT', '10000')
                
                # Try to ping our own service
                try:
                    base_url = os.environ.get('RENDER_EXTERNAL_URL', f'http://localhost:{port}')
                    response = requests.get(f'{base_url}/ping', timeout=5)
                    self.ping_count += 1
                    self.log(f"♻️ Auto-ping #{self.ping_count}")
                except:
                    # Fallback to local ping
                    try:
                        requests.get(f'http://localhost:{port}/ping', timeout=2)
                    except:
                        pass
                        
            except Exception as e:
                self.log(f"⚠️ Keep-alive error: {e}")
    
    def log(self, message):
        if CONFIG['debug']:
            timestamp = datetime.now().strftime('%H:%M:%S')
            print(f"[{timestamp}] {message}")
    
    def stop(self):
        self.running = False

# Initialize keep-alive
keeper = KeepAliveSystem()

# ==================== SITE DETECTION LOGIC ====================
class SiteDetector:
    """Detects if a site blocks iframes and provides alternative access methods"""
    
    # Sites that ALWAYS block iframes
    BLOCKED_SITES = {
        'google.com': {
            'name': 'Google',
            'reason': 'Uses X-Frame-Options and CSP to block embedding',
            'alternative': 'Open in new tab',
            'category': 'search',
            'priority': 1
        },
        'github.com': {
            'name': 'GitHub',
            'reason': 'Uses Content-Security-Policy to prevent clickjacking',
            'alternative': 'Direct redirect or new tab',
            'category': 'development',
            'priority': 1
        },
        'github.dev': {
            'name': 'GitHub Codespaces',
            'reason': 'Development environment requires authentication and blocks iframes',
            'alternative': 'Direct redirect with authentication',
            'category': 'development',
            'priority': 10,  # Highest priority - ALWAYS redirect immediately
            'immediate_action': 'redirect'
        },
        'youtube.com': {
            'name': 'YouTube',
            'reason': 'Video platform blocks embedding without explicit permissions',
            'alternative': 'Use YouTube embed API or open in new tab',
            'category': 'media',
            'priority': 1
        },
        'facebook.com': {
            'name': 'Facebook',
            'reason': 'Social media platform blocks iframes for security',
            'alternative': 'Open in new tab',
            'category': 'social',
            'priority': 1
        },
        'twitter.com': {
            'name': 'Twitter/X',
            'reason': 'Blocks iframes to prevent UI manipulation',
            'alternative': 'Open in new tab',
            'category': 'social',
            'priority': 1
        }
    }
    
    # Sites that USUALLY work in iframes
    ALLOWED_SITES = {
        'wikipedia.org': 'Wikipedia - Usually allows embedding',
        'getbootstrap.com': 'Bootstrap Docs - Allows embedding',
        'httpbin.org': 'HTTP Bin - Test site that allows embedding',
        'example.com': 'Example domain - Allows embedding',
        'docs.python.org': 'Python Documentation - Allows embedding'
    }
    
    @classmethod
    def analyze_url(cls, url):
        """Analyze a URL and determine how to handle it"""
        try:
            parsed = urllib.parse.urlparse(url)
            domain = parsed.netloc.lower()
            
            # Remove www. prefix if present
            if domain.startswith('www.'):
                domain = domain[4:]
            
            # Check if domain is in blocked list
            for blocked_domain, info in cls.BLOCKED_SITES.items():
                if blocked_domain in domain:
                    # GitHub Codespaces gets special handling
                    if 'github.dev' in domain:
                        return {
                            'status': 'blocked',
                            'domain': domain,
                            'name': info['name'],
                            'reason': info['reason'],
                            'alternative': info['alternative'],
                            'category': info['category'],
                            'action': 'redirect',
                            'immediate': True,
                            'priority': info.get('priority', 1),
                            'redirect_url': f'/redirect?url={urllib.parse.quote(url)}'
                        }
                    
                    # Other blocked sites
                    return {
                        'status': 'blocked',
                        'domain': domain,
                        'name': info['name'],
                        'reason': info['reason'],
                        'alternative': info['alternative'],
                        'category': info['category'],
                        'action': 'redirect' if 'github.dev' in domain else 'new_tab',
                        'priority': info.get('priority', 1)
                    }
            
            # Check if domain is in allowed list
            for allowed_domain, description in cls.ALLOWED_SITES.items():
                if allowed_domain in domain:
                    return {
                        'status': 'allowed',
                        'domain': domain,
                        'description': description,
                        'action': 'iframe'
                    }
            
            # Unknown domain - try iframe first
            return {
                'status': 'unknown',
                'domain': domain,
                'action': 'try_iframe',
                'warning': 'This site may or may not work in iframe'
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e),
                'action': 'try_iframe'
            }
    
    @classmethod
    def get_redirect_html(cls, url, delay=2):
        """Generate HTML for automatic redirect"""
        return f'''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Redirecting to GitHub Codespaces...</title>
            <meta http-equiv="refresh" content="{delay};url={url}">
            <style>
                body {{ 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
                    color: white;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }}
                .container {{
                    text-align: center;
                    padding: 40px;
                    background: rgba(255, 255, 255, 0.1);
                    backdrop-filter: blur(10px);
                    border-radius: 20px;
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    max-width: 600px;
                }}
                .spinner {{
                    border: 4px solid rgba(255, 255, 255, 0.1);
                    border-top: 4px solid #3b82f6;
                    border-radius: 50%;
                    width: 50px;
                    height: 50px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }}
                @keyframes spin {{
                    0% {{ transform: rotate(0deg); }}
                    100% {{ transform: rotate(360deg); }}
                }}
                .logo {{
                    font-size: 48px;
                    margin-bottom: 20px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="logo">🚀</div>
                <div class="spinner"></div>
                <h2>Redirecting to GitHub Codespaces</h2>
                <p>GitHub Codespaces cannot be displayed in an iframe for security reasons.</p>
                <p>You are being redirected to:</p>
                <p><strong><code>{url}</code></strong></p>
                <p>Redirecting in {delay} seconds...</p>
                <p>If not redirected, <a href="{url}" style="color: #60a5fa; text-decoration: underline;">click here to access directly</a>.</p>
                <div style="margin-top: 20px; padding: 10px; background: rgba(255,255,255,0.05); border-radius: 8px;">
                    <small>Note: GitHub Codespaces requires direct browser access for proper authentication and functionality.</small>
                </div>
            </div>
        </body>
        </html>
        '''

# ==================== MAIN HTML TEMPLATE ====================
HTML_TEMPLATE = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌐 Universal Smart Browser</title>
    <style>
        :root {
            --primary: #3b82f6;
            --primary-dark: #1d4ed8;
            --secondary: #6b7280;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
            --text-light: #f8fafc;
            --text-muted: #94a3b8;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, var(--bg-dark) 0%, #1e293b 100%);
            color: var(--text-light);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .header {
            background: rgba(0, 0, 0, 0.9);
            padding: 15px 20px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
        }
        
        .url-container {
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .url-input {
            flex: 1;
            min-width: 300px;
            padding: 12px 18px;
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid var(--primary);
            border-radius: 10px;
            color: var(--text-light);
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .url-input:focus {
            outline: none;
            border-color: #60a5fa;
            box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.3);
            background: rgba(255, 255, 255, 0.15);
        }
        
        .btn {
            padding: 12px 24px;
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(37, 99, 235, 0.4);
        }
        
        .btn-secondary {
            background: linear-gradient(135deg, var(--secondary) 0%, #4b5563 100%);
        }
        
        .btn-success {
            background: linear-gradient(135deg, var(--success) 0%, #059669 100%);
        }
        
        .btn-warning {
            background: linear-gradient(135deg, var(--warning) 0%, #d97706 100%);
        }
        
        .btn-danger {
            background: linear-gradient(135deg, var(--danger) 0%, #dc2626 100%);
        }
        
        .btn-immediate {
            background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        
        .content {
            flex: 1;
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        .card {
            background: var(--bg-card);
            border-radius: 12px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-left: 10px;
        }
        
        .status-online { background: var(--success); }
        .status-warning { background: var(--warning); }
        .status-danger { background: var(--danger); }
        
        .site-info {
            margin: 15px 0;
            padding: 15px;
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.05);
        }
        
        .iframe-container {
            width: 100%;
            flex: 1;
            min-height: 500px;
            border-radius: 12px;
            overflow: hidden;
            border: 2px solid rgba(255, 255, 255, 0.1);
            background: black;
        }
        
        .browser-frame {
            width: 100%;
            height: 100%;
            border: none;
        }
        
        .loading {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: var(--text-muted);
        }
        
        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.1);
            border-top: 4px solid var(--primary);
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin-bottom: 15px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .stats-bar {
            background: rgba(0, 0, 0, 0.8);
            padding: 10px 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: var(--text-muted);
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .github-warning {
            background: linear-gradient(135deg, rgba(139, 92, 246, 0.1) 0%, rgba(124, 58, 237, 0.1) 100%);
            border-left: 4px solid #8b5cf6;
            padding: 12px;
            margin: 10px 0;
            border-radius: 6px;
        }
        
        @media (max-width: 768px) {
            .url-input { min-width: auto; }
            .btn { padding: 10px 16px; font-size: 14px; }
            .content { padding: 10px; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="url-container">
            <input type="text" class="url-input" id="urlInput" 
                   placeholder="Enter any website URL..."
                   value="{{ default_url }}">
            <button class="btn" onclick="loadWebsite()" id="loadBtn">
                <span>🌐</span> Smart Load
            </button>
            <button class="btn btn-secondary" onclick="toggleAdvanced()" id="advancedBtn">
                <span>⚙️</span> Advanced
            </button>
        </div>
    </div>
    
    <div class="content">
        <!-- Site Analysis Card -->
        <div class="card" id="analysisCard">
            <h3>
                Site Analysis
                <span class="status-badge" id="analysisStatus">Ready</span>
            </h3>
            <div class="site-info" id="siteInfo">
                <p>Enter a URL above to analyze site compatibility</p>
                <div class="github-warning" id="githubWarning" style="display: none;">
                    <strong>⚠️ GitHub Codespaces Detected</strong>
                    <p style="margin: 5px 0; font-size: 14px;">This site requires direct access and cannot be displayed in an iframe.</p>
                </div>
            </div>
            <div class="action-buttons" id="actionButtons">
                <button class="btn btn-success" onclick="loadWebsite()">
                    🚀 Smart Load
                </button>
            </div>
        </div>
        
        <!-- Browser Container -->
        <div class="card">
            <h3>Browser View</h3>
            <div class="iframe-container">
                <div class="loading" id="loading" style="display: none;">
                    <div class="spinner"></div>
                    <p id="loadingText">Loading...</p>
                </div>
                <iframe class="browser-frame" id="browserFrame" 
                        sandbox="allow-same-origin allow-scripts allow-forms allow-popups"
                        allow="camera; microphone; fullscreen">
                </iframe>
                <div id="redirectMessage" style="display: none; text-align: center; padding: 40px;">
                    <h3>🚀 Redirecting to GitHub Codespaces</h3>
                    <p>This site cannot be displayed in an iframe.</p>
                    <p>You will be redirected automatically in <span id="countdown">3</span> seconds...</p>
                    <button class="btn btn-immediate" onclick="forceImmediateRedirect()">
                        🔥 Redirect Now
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Advanced Panel (Hidden by default) -->
        <div class="card" id="advancedPanel" style="display: none;">
            <h3>Advanced Settings</h3>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 15px;">
                <div>
                    <label style="display: block; margin-bottom: 5px; font-size: 14px;">Load Method</label>
                    <select id="loadMethod" style="width: 100%; padding: 8px; border-radius: 6px; background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2);">
                        <option value="auto">Auto-detect (Recommended)</option>
                        <option value="iframe">Force iFrame</option>
                        <option value="redirect">Force Redirect</option>
                        <option value="newtab">Force New Tab</option>
                    </select>
                </div>
                <div>
                    <label style="display: block; margin-bottom: 5px; font-size: 14px;">Auto-refresh</label>
                    <select id="autoRefresh" style="width: 100%; padding: 8px; border-radius: 6px; background: rgba(255,255,255,0.1); color: white; border: 1px solid rgba(255,255,255,0.2);">
                        <option value="0">Disabled</option>
                        <option value="300000">Every 5 minutes</option>
                        <option value="1800000">Every 30 minutes</option>
                        <option value="3600000">Every hour</option>
                    </select>
                </div>
                <div>
                    <label style="display: block; margin-bottom: 5px; font-size: 14px;">Debug Mode</label>
                    <label style="display: flex; align-items: center; gap: 8px; cursor: pointer;">
                        <input type="checkbox" id="debugMode">
                        <span>Enable debug logging</span>
                    </label>
                </div>
            </div>
        </div>
    </div>
    
    <div class="stats-bar">
        <div>
            <span id="connectionStatus">● Online</span>
            • Uptime: <span id="uptime">0h 0m</span>
            • Method: <span id="currentMethod">Auto-detect</span>
        </div>
        <div>
            <span id="currentDomain">github.dev</span>
        </div>
    </div>

    <script>
        // State management
        let state = {
            currentUrl: '{{ default_url }}',
            currentAnalysis: null,
            startTime: Date.now(),
            autoRefreshInterval: null,
            debugMode: false,
            lastLoadMethod: 'auto',
            immediateRedirect: false
        };
        
        // DOM Elements
        const urlInput = document.getElementById('urlInput');
        const loadBtn = document.getElementById('loadBtn');
        const analysisCard = document.getElementById('analysisCard');
        const analysisStatus = document.getElementById('analysisStatus');
        const siteInfo = document.getElementById('siteInfo');
        const actionButtons = document.getElementById('actionButtons');
        const loading = document.getElementById('loading');
        const loadingText = document.getElementById('loadingText');
        const browserFrame = document.getElementById('browserFrame');
        const connectionStatus = document.getElementById('connectionStatus');
        const uptimeEl = document.getElementById('uptime');
        const currentMethod = document.getElementById('currentMethod');
        const currentDomain = document.getElementById('currentDomain');
        const advancedPanel = document.getElementById('advancedPanel');
        const loadMethodSelect = document.getElementById('loadMethod');
        const autoRefreshSelect = document.getElementById('autoRefresh');
        const debugModeCheckbox = document.getElementById('debugMode');
        const githubWarning = document.getElementById('githubWarning');
        const redirectMessage = document.getElementById('redirectMessage');
        const countdownEl = document.getElementById('countdown');
        
        // Initialize
        function init() {
            updateUptime();
            setupEventListeners();
            
            // Set initial URL from input
            state.currentUrl = urlInput.value;
            currentDomain.textContent = 'github.dev';
            
            // Check if it's a GitHub Codespaces URL
            if (state.currentUrl.includes('github.dev')) {
                showGitHubWarning();
                // Auto-analyze GitHub URLs
                setTimeout(() => analyzeUrl(state.currentUrl), 500);
            }
            
            // Start uptime updater
            setInterval(updateUptime, 60000);
            
            // Start connection monitor
            setInterval(checkConnection, 30000);
            
            log('Browser initialized');
        }
        
        function setupEventListeners() {
            // URL input
            urlInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') loadWebsite();
            });
            
            // URL change detection
            urlInput.addEventListener('input', (e) => {
                const url = e.target.value;
                if (url.includes('github.dev')) {
                    showGitHubWarning();
                } else {
                    hideGitHubWarning();
                }
            });
            
            // Iframe events
            browserFrame.addEventListener('load', handleIframeLoad);
            browserFrame.addEventListener('error', handleIframeError);
            
            // Advanced settings
            loadMethodSelect.addEventListener('change', updateLoadMethod);
            autoRefreshSelect.addEventListener('change', updateAutoRefresh);
            debugModeCheckbox.addEventListener('change', updateDebugMode);
        }
        
        function showGitHubWarning() {
            githubWarning.style.display = 'block';
            siteInfo.innerHTML = `
                <div class="github-warning">
                    <strong>🚀 GitHub Codespaces Detected</strong>
                    <p style="margin: 5px 0; font-size: 14px;">This development environment requires direct browser access and cannot be embedded in an iframe.</p>
                    <p style="margin: 5px 0; font-size: 13px; color: #cbd5e1;">Smart Load will automatically redirect you to the site.</p>
                </div>
            `;
        }
        
        function hideGitHubWarning() {
            githubWarning.style.display = 'none';
        }
        
        async function analyzeUrl(url) {
            if (!url) return;
            
            try {
                loadingText.textContent = 'Analyzing site compatibility...';
                loading.style.display = 'flex';
                browserFrame.style.display = 'none';
                
                // Show immediate analysis for GitHub Codespaces
                if (url.includes('github.dev')) {
                    state.currentAnalysis = {
                        status: 'blocked',
                        domain: 'github.dev',
                        name: 'GitHub Codespaces',
                        reason: 'Development environment requires direct access',
                        action: 'redirect',
                        immediate: true
                    };
                    updateAnalysisUI(state.currentAnalysis);
                    return;
                }
                
                // Call backend analysis for other sites
                const response = await fetch(`/analyze?url=${encodeURIComponent(url)}`);
                
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                
                const data = await response.json();
                console.log('Analysis response:', data);
                
                state.currentAnalysis = data;
                updateAnalysisUI(data);
                
            } catch (error) {
                console.error('Analysis error:', error);
                
                // Fallback analysis for errors
                const domain = extractDomain(url);
                state.currentAnalysis = {
                    status: 'unknown',
                    domain: domain,
                    action: 'try_iframe',
                    error: error.message
                };
                updateAnalysisUI(state.currentAnalysis);
            }
        }
        
        function extractDomain(url) {
            try {
                const parsed = new URL(url);
                return parsed.hostname.replace('www.', '');
            } catch {
                return url.split('/')[2] || url;
            }
        }
        
        function updateAnalysisUI(analysis) {
            // Update status badge
            analysisStatus.textContent = analysis.status.toUpperCase();
            analysisStatus.className = 'status-badge';
            
            let infoHTML = '';
            
            switch(analysis.status) {
                case 'blocked':
                    analysisStatus.classList.add('status-danger');
                    infoHTML = `
                        <p><strong>${analysis.name || analysis.domain}</strong></p>
                        <p>${analysis.reason || 'This site blocks iframe embedding for security.'}</p>
                        <p><small>${analysis.alternative || 'Use redirect or new tab method.'}</small></p>
                    `;
                    
                    if (analysis.immediate) {
                        infoHTML += `
                            <div class="github-warning">
                                <strong>⚡ Immediate Redirect Required</strong>
                                <p>This site requires direct browser access. Click "Smart Load" to redirect.</p>
                            </div>
                        `;
                    }
                    break;
                    
                case 'allowed':
                    analysisStatus.classList.add('status-success');
                    infoHTML = `
                        <p><strong>${analysis.domain}</strong></p>
                        <p>${analysis.description || 'This site should work in iframe.'}</p>
                        <p><small>You can load this site directly in the iframe.</small></p>
                    `;
                    break;
                    
                case 'unknown':
                    analysisStatus.classList.add('status-warning');
                    infoHTML = `
                        <p><strong>${analysis.domain}</strong></p>
                        <p>${analysis.warning || 'Compatibility unknown'}</p>
                        <p><small>Will try iframe first, fallback if needed.</small></p>
                    `;
                    break;
                    
                case 'error':
                    analysisStatus.classList.add('status-danger');
                    infoHTML = `
                        <p><strong>Analysis Error</strong></p>
                        <p>${analysis.error || 'Failed to analyze URL'}</p>
                        <p><small>Will try iframe method as fallback.</small></p>
                    `;
                    break;
            }
            
            siteInfo.innerHTML = infoHTML;
            
            // Update action buttons
            updateActionButtons(analysis);
            
            // Update domain display
            currentDomain.textContent = analysis.domain || extractDomain(state.currentUrl);
        }
        
        function updateActionButtons(analysis) {
            actionButtons.innerHTML = '';
            
            // Smart Load button (always show)
            const smartBtn = document.createElement('button');
            smartBtn.className = analysis.immediate ? 'btn btn-immediate' : 'btn';
            smartBtn.innerHTML = analysis.immediate ? '🚀 Immediate Redirect' : '🌐 Smart Load';
            smartBtn.onclick = () => loadWebsite();
            actionButtons.appendChild(smartBtn);
            
            // Specific method button based on analysis
            if (analysis.action === 'redirect' || analysis.immediate) {
                const redirectBtn = document.createElement('button');
                redirectBtn.className = 'btn btn-warning';
                redirectBtn.innerHTML = '🔗 Secure Redirect';
                redirectBtn.onclick = () => loadWithMethod('redirect');
                actionButtons.appendChild(redirectBtn);
            }
            
            if (analysis.action === 'new_tab' && !analysis.immediate) {
                const newTabBtn = document.createElement('button');
                newTabBtn.className = 'btn btn-secondary';
                newTabBtn.innerHTML = '↗️ Open New Tab';
                newTabBtn.onclick = () => loadWithMethod('newtab');
                actionButtons.appendChild(newTabBtn);
            }
            
            if (analysis.action === 'iframe' || analysis.action === 'try_iframe') {
                const iframeBtn = document.createElement('button');
                iframeBtn.className = 'btn btn-success';
                iframeBtn.innerHTML = '📱 Load in iFrame';
                iframeBtn.onclick = () => loadWithMethod('iframe');
                actionButtons.appendChild(iframeBtn);
            }
            
            // Copy URL button
            const copyBtn = document.createElement('button');
            copyBtn.className = 'btn btn-secondary';
            copyBtn.innerHTML = '📋 Copy URL';
            copyBtn.onclick = copyUrl;
            actionButtons.appendChild(copyBtn);
        }
        
        async function loadWebsite() {
            const url = urlInput.value.trim();
            if (!url) {
                showError('Please enter a URL');
                return;
            }
            
            // Validate URL
            let targetUrl = url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
                targetUrl = 'https://' + url;
                urlInput.value = targetUrl;
            }
            
            state.currentUrl = targetUrl;
            currentDomain.textContent = extractDomain(targetUrl);
            
            // Check for immediate redirect (GitHub Codespaces)
            if (targetUrl.includes('github.dev')) {
                console.log('GitHub Codespaces detected - forcing immediate redirect');
                startImmediateRedirect(targetUrl);
                return;
            }
            
            // Analyze URL first (for non-GitHub sites)
            await analyzeUrl(targetUrl);
            
            // Determine load method
            const method = loadMethodSelect.value === 'auto' 
                ? (state.currentAnalysis?.action || 'try_iframe')
                : loadMethodSelect.value;
            
            state.lastLoadMethod = method;
            currentMethod.textContent = method.replace('_', ' ') || 'Auto-detect';
            
            // Execute load
            loadWithMethod(method);
        }
        
        function startImmediateRedirect(url) {
            console.log('Starting immediate redirect to:', url);
            
            // Hide iframe, show redirect message
            browserFrame.style.display = 'none';
            loading.style.display = 'none';
            redirectMessage.style.display = 'block';
            
            // Start countdown
            let countdown = 3;
            countdownEl.textContent = countdown;
            
            const countdownInterval = setInterval(() => {
                countdown--;
                countdownEl.textContent = countdown;
                
                if (countdown <= 0) {
                    clearInterval(countdownInterval);
                    executeRedirect(url);
                }
            }, 1000);
            
            // Update UI
            analysisStatus.textContent = 'REDIRECTING';
            analysisStatus.className = 'status-badge status-danger';
            
            // Show redirect button
            actionButtons.innerHTML = `
                <button class="btn btn-immediate" onclick="executeRedirect('${url}')">
                    🔥 Redirect Now
                </button>
                <button class="btn btn-secondary" onclick="cancelRedirect()">
                    ✕ Cancel
                </button>
            `;
        }
        
        function executeRedirect(url) {
            console.log('Executing redirect to:', url);
            window.location.href = `/redirect?url=${encodeURIComponent(url)}`;
        }
        
        function forceImmediateRedirect() {
            executeRedirect(state.currentUrl);
        }
        
        function cancelRedirect() {
            redirectMessage.style.display = 'none';
            browserFrame.style.display = 'none';
            loading.style.display = 'flex';
            loadingText.textContent = 'Ready to browse';
            
            // Reset action buttons
            if (state.currentAnalysis) {
                updateActionButtons(state.currentAnalysis);
            }
        }
        
        function loadWithMethod(method) {
            const url = state.currentUrl;
            
            // Special handling for GitHub Codespaces
            if (url.includes('github.dev') && method !== 'redirect') {
                console.log('Overriding method to redirect for GitHub Codespaces');
                method = 'redirect';
            }
            
            switch(method) {
                case 'iframe':
                case 'try_iframe':
                    loadInIframe(url);
                    break;
                    
                case 'redirect':
                    // Use backend redirect endpoint
                    if (url.includes('github.dev')) {
                        startImmediateRedirect(url);
                    } else {
                        window.location.href = `/redirect?url=${encodeURIComponent(url)}`;
                    }
                    break;
                    
                case 'newtab':
                    window.open(url, '_blank');
                    showMessage('Opening in new tab...');
                    break;
                    
                default:
                    loadInIframe(url);
            }
        }
        
        function loadInIframe(url) {
            loadingText.textContent = 'Loading in iFrame...';
            loading.style.display = 'flex';
            browserFrame.style.display = 'none';
            redirectMessage.style.display = 'none';
            
            // Set iframe source with cache busting
            const timestamp = new Date().getTime();
            const cacheBuster = url.includes('?') ? '&' : '?';
            browserFrame.src = `${url}${cacheBuster}_t=${timestamp}`;
            
            // Set timeout for iframe load
            setTimeout(() => {
                if (loading.style.display === 'flex') {
                    // If still loading after timeout, show fallback
                    console.log('iFrame load timeout - site may be blocking');
                    showError('Site may be blocking iframe. Try redirect method.');
                    browserFrame.style.display = 'none';
                    loading.style.display = 'flex';
                    loadingText.textContent = 'Site may be blocking iframe access';
                }
            }, 10000); // 10 second timeout
        }
        
        function handleIframeLoad() {
            console.log('iFrame loaded successfully');
            loading.style.display = 'none';
            browserFrame.style.display = 'block';
            redirectMessage.style.display = 'none';
            
            if (state.currentAnalysis) {
                analysisStatus.textContent = 'LOADED';
                analysisStatus.className = 'status-badge status-success';
            }
            
            // Start auto-refresh if enabled
            startAutoRefresh();
        }
        
        function handleIframeError() {
            console.error('iFrame failed to load');
            showError('Site blocked iframe embedding. Use redirect or new tab.');
            analysisStatus.textContent = 'BLOCKED';
            analysisStatus.className = 'status-badge status-danger';
            
            // Show alternative methods
            siteInfo.innerHTML += `
                <div style="margin-top: 10px; padding: 10px; background: rgba(239, 68, 68, 0.1); border-radius: 6px;">
                    <p><strong>Alternative Access:</strong></p>
                    <button class="btn btn-warning" onclick="loadWithMethod('redirect')" style="margin-top: 5px;">
                        🔗 Use Secure Redirect
                    </button>
                </div>
            `;
        }
        
        function startAutoRefresh() {
            // Clear existing interval
            if (state.autoRefreshInterval) {
                clearInterval(state.autoRefreshInterval);
            }
            
            // Get interval from select
            const interval = parseInt(autoRefreshSelect.value);
            if (interval > 0) {
                state.autoRefreshInterval = setInterval(() => {
                    if (browserFrame.src && browserFrame.src !== 'about:blank') {
                        log('Auto-refreshing page...');
                        browserFrame.src = browserFrame.src;
                    }
                }, interval);
                
                log(`Auto-refresh enabled: every ${interval/60000} minutes`);
            }
        }
        
        function updateUptime() {
            const elapsed = Date.now() - state.startTime;
            const hours = Math.floor(elapsed / 3600000);
            const minutes = Math.floor((elapsed % 3600000) / 60000);
            uptimeEl.textContent = `${hours}h ${minutes}m`;
        }
        
        function checkConnection() {
            fetch('/ping')
                .then(() => {
                    connectionStatus.textContent = '● Online';
                    connectionStatus.style.color = '#10b981';
                })
                .catch(() => {
                    connectionStatus.textContent = '● Offline';
                    connectionStatus.style.color = '#ef4444';
                });
        }
        
        function copyUrl() {
            navigator.clipboard.writeText(state.currentUrl)
                .then(() => {
                    showMessage('URL copied to clipboard!');
                })
                .catch(err => {
                    showError('Failed to copy URL');
                });
        }
        
        function showError(message) {
            loadingText.textContent = message;
            loading.style.display = 'flex';
            browserFrame.style.display = 'none';
            redirectMessage.style.display = 'none';
            
            // Show error in analysis card
            siteInfo.innerHTML = `<p style="color: #fca5a5;">${message}</p>`;
        }
        
        function showMessage(message) {
            const originalText = loadingText.textContent;
            loadingText.textContent = message;
            setTimeout(() => {
                loadingText.textContent = originalText;
            }, 3000);
        }
        
        function toggleAdvanced() {
            const isVisible = advancedPanel.style.display !== 'none';
            advancedPanel.style.display = isVisible ? 'none' : 'block';
            advancedBtn.innerHTML = isVisible ? '<span>⚙️</span> Advanced' : '<span>✕</span> Close';
        }
        
        function updateLoadMethod() {
            state.lastLoadMethod = loadMethodSelect.value;
            currentMethod.textContent = loadMethodSelect.value === 'auto' 
                ? 'Auto-detect' 
                : loadMethodSelect.value;
        }
        
        function updateAutoRefresh() {
            startAutoRefresh();
        }
        
        function updateDebugMode() {
            state.debugMode = debugModeCheckbox.checked;
            log(`Debug mode: ${state.debugMode ? 'ON' : 'OFF'}`);
        }
        
        function log(message) {
            if (state.debugMode) {
                const timestamp = new Date().toLocaleTimeString();
                console.log(`[${timestamp}] ${message}`);
            }
        }
        
        // Initialize on load
        window.addEventListener('load', init);
    </script>
</body>
</html>
'''

# ==================== FLASK ROUTES ====================

@app.route('/')
def index():
    """Main browser interface"""
    return render_template_string(
        HTML_TEMPLATE,
        default_url=CONFIG['default_url']
    )

@app.route('/analyze')
def analyze_url():
    """Analyze a URL for iframe compatibility"""
    url = request.args.get('url', '').strip()
    
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    
    # Add protocol if missing
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    # Special handling for GitHub Codespaces
    if 'github.dev' in url:
        return jsonify({
            'status': 'blocked',
            'domain': 'github.dev',
            'name': 'GitHub Codespaces',
            'reason': 'Development environment requires direct browser access',
            'alternative': 'Direct redirect required',
            'category': 'development',
            'action': 'redirect',
            'immediate': True,
            'priority': 10
        })
    
    # Analyze URL for other sites
    analysis = SiteDetector.analyze_url(url)
    
    return jsonify(analysis)

@app.route('/redirect')
def redirect_url():
    """Redirect to a URL (for blocked sites)"""
    url = request.args.get('url', '').strip()
    
    if not url:
        return jsonify({'error': 'No URL provided'}), 400
    
    # Add protocol if missing
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    # Special message for GitHub Codespaces
    if 'github.dev' in url:
        return SiteDetector.get_redirect_html(url, CONFIG['auto_redirect_delay'])
    
    # Return redirect HTML for other sites
    return SiteDetector.get_redirect_html(url, CONFIG['auto_redirect_delay'])

@app.route('/direct/<path:url>')
def direct_url(url):
    """Direct URL access with protocol fix"""
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    return redirect(url)

@app.route('/ping')
def ping():
    """Keep-alive endpoint"""
    return jsonify({
        'status': 'online',
        'timestamp': datetime.now().isoformat(),
        'pings': keeper.ping_count,
        'uptime': time.time() - keeper.start_time
    })

@app.route('/health')
def health():
    """Health check for Render"""
    return "OK", 200

@app.route('/status')
def status():
    """Service status"""
    uptime = time.time() - keeper.start_time
    hours = int(uptime // 3600)
    minutes = int((uptime % 3600) // 60)
    
    return jsonify({
        'status': 'running',
        'uptime': f'{hours}h {minutes}m',
        'uptime_seconds': uptime,
        'ping_count': keeper.ping_count,
        'service': 'universal-browser',
        'version': '2.0',
        'timestamp': datetime.now().isoformat()
    })

# ==================== TEST ENDPOINTS ====================

@app.route('/test')
def test():
    """Test endpoint to verify backend is working"""
    return jsonify({
        'status': 'ok',
        'message': 'Universal Browser backend is working!',
        'endpoints': {
            '/': 'Main browser interface',
            '/analyze?url=...': 'URL analysis',
            '/redirect?url=...': 'Secure redirect',
            '/status': 'Service status',
            '/health': 'Health check'
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/debug-analyze')
def debug_analyze():
    """Debug analysis endpoint"""
    url = request.args.get('url', 'https://example.com')
    
    return jsonify({
        'status': 'debug',
        'url': url,
        'domain': 'example.com',
        'action': 'iframe',
        'timestamp': datetime.now().isoformat()
    })

# ==================== STARTUP ====================

# REMOVE THIS BLOCK FOR DEPLOYMENT:
# if __name__ == '__main__':
#     port = int(os.environ.get('PORT', 10000))
#     
#     print(f"""
#     🌐 UNIVERSAL SMART BROWSER STARTING...
#     =========================================
#     
#     🚀 SMART FEATURES:
#     • Auto-detects blocked sites (Google, GitHub, etc.)
#     • Special handling for GitHub Codespaces
#     • Smart fallback to redirect/new tab
#     • 24/7 uptime with auto-ping
#     • Works on Render free tier
#     
#     📡 ENDPOINTS:
#     • Main Browser: http://localhost:{port}/
#     • URL Analysis: /analyze?url=...
#     • Secure Redirect: /redirect?url=...
#     • Status: /status
#     • Health: /health
#     • Test: /test
#     
#     ⚙️ CONFIGURATION:
#     • Port: {port}
#     • Default URL: {CONFIG['default_url']}
#     • Auto-ping: Every {CONFIG['keep_alive_interval']//60} minutes
#     • iFrame Timeout: {CONFIG['iframe_timeout']} seconds
#     
#     =========================================
#     ✅ Service will handle ANY website smartly
#     """)
#     
#     # Run the app
#     app.run(
#         host='0.0.0.0',
#         port=port,
#         debug=False,
#         threaded=True
#     )
