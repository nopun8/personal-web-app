#!/usr/bin/env python3
"""
S M Fahim Alam's Personal Web Application
A Flask web application with REST API, optimized for CSC Rahti platform.
"""

import os
import sys
import logging
from datetime import datetime
from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
import socket
import platform
try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

# Create Flask application
app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'fahim-personal-app-key')
app.config['DEBUG'] = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'

# Personal Information - MAIN REQUIREMENT
DEVELOPER_NAME = "S M Fahim Alam"
DEVELOPER_EMAIL = "salsm24@students.oamk.fi"
GITHUB_REPO = "https://github.com/nopun8/personal-web-app"
LINKEDIN_PROFILE = "https://linkedin.com/in/smfahimalam"

def get_system_info():
    """Get comprehensive system information for display"""
    info = {
        'developer': DEVELOPER_NAME,
        'email': DEVELOPER_EMAIL,
        'github': GITHUB_REPO,
        'linkedin': LINKEDIN_PROFILE,
        'hostname': socket.gethostname(),
        'platform': platform.platform(),
        'python_version': platform.python_version(),
        'timestamp': datetime.now().isoformat(),
        'environment': {
            'user': os.environ.get('USER', 'unknown'),
            'home': os.environ.get('HOME', 'unknown'),
            'port': os.environ.get('PORT', '8080'),
            'flask_env': os.environ.get('FLASK_ENV', 'production')
        }
    }
    
    # Add system stats if psutil is available
    if HAS_PSUTIL:
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            info['system_stats'] = {
                'cpu_usage': f"{cpu_percent}%",
                'memory_usage': f"{memory.percent}%",
                'disk_usage': f"{disk.percent}%",
                'memory_total': f"{memory.total // (1024**3)} GB",
                'disk_total': f"{disk.total // (1024**3)} GB"
            }
        except Exception as e:
            logger.warning(f"Could not get system stats: {e}")
            
    return info

@app.route('/')
def home():
    """Home page route"""
    logger.info(f"Home page requested by {DEVELOPER_NAME}'s app")
    system_info = get_system_info()
    return render_template('index.html', system_info=system_info)

@app.route('/api/name')
def get_name():
    """Return developer name - MAIN REQUIREMENT for identification"""
    logger.info("Name API endpoint called - main requirement")
    return jsonify({
        "name": DEVELOPER_NAME,
        "message": f"Hello! I'm {DEVELOPER_NAME}",
        "timestamp": datetime.now().isoformat(),
        "endpoint": "/api/name",
        "purpose": "Developer identification as required"
    })

@app.route('/health')
def health_check():
    """Health check endpoint for Kubernetes/OpenShift"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'hostname': socket.gethostname(),
        'developer': DEVELOPER_NAME
    })

@app.route('/ready')
def readiness_check():
    """Readiness check endpoint for Kubernetes/OpenShift"""
    return jsonify({
        'status': 'ready',
        'timestamp': datetime.now().isoformat(),
        'hostname': socket.gethostname(),
        'developer': DEVELOPER_NAME
    })

@app.route('/info')
def info():
    """System information endpoint (JSON)"""
    return jsonify(get_system_info())

@app.route('/api/data')
def api_data():
    """Demo API endpoint with personal data"""
    data = {
        'message': f'Welcome to {DEVELOPER_NAME}\'s Personal Web Application!',
        'developer': DEVELOPER_NAME,
        'data': [
            {'id': 1, 'name': 'Personal Project 1', 'value': 'Web Development', 'status': 'Active'},
            {'id': 2, 'name': 'Personal Project 2', 'value': 'API Design', 'status': 'In Progress'},
            {'id': 3, 'name': 'Personal Project 3', 'value': 'Cloud Deployment', 'status': 'Learning'}
        ],
        'timestamp': datetime.now().isoformat(),
        'server': socket.gethostname(),
        'github': GITHUB_REPO
    }
    return jsonify(data)

@app.route('/api/portfolio')
def get_portfolio():
    """Personal portfolio endpoint"""
    portfolio = {
        'developer': DEVELOPER_NAME,
        'title': 'Full Stack Developer & Student',
        'bio': f'Hello! I\'m {DEVELOPER_NAME}, a passionate developer learning modern web technologies and cloud platforms like CSC Rahti.',
        'skills': [
            {'name': 'Python', 'level': 85, 'category': 'Backend'},
            {'name': 'Flask', 'level': 80, 'category': 'Backend'},
            {'name': 'JavaScript', 'level': 75, 'category': 'Frontend'},
            {'name': 'HTML/CSS', 'level': 85, 'category': 'Frontend'},
            {'name': 'Docker', 'level': 70, 'category': 'DevOps'},
            {'name': 'Git', 'level': 80, 'category': 'Tools'},
            {'name': 'OpenShift/Rahti', 'level': 65, 'category': 'Cloud'}
        ],
        'projects': [
            {
                'name': 'Personal Web Application',
                'description': 'This application - A personalized web app with REST API deployed on CSC Rahti',
                'technologies': ['Python', 'Flask', 'JavaScript', 'Docker', 'OpenShift'],
                'github': GITHUB_REPO,
                'status': 'Active'
            }
        ],
        'contact': {
            'email': DEVELOPER_EMAIL,
            'github': GITHUB_REPO,
            'linkedin': LINKEDIN_PROFILE
        },
        'timestamp': datetime.now().isoformat()
    }
    
    return jsonify(portfolio)

@app.route('/api/contact', methods=['POST'])
def contact():
    """Contact form endpoint"""
    try:
        data = request.get_json()
        logger.info(f"Contact form submission received: {data.get('name', 'Anonymous')}")
        
        return jsonify({
            'message': f'Thank you for your message! I ({DEVELOPER_NAME}) will get back to you soon.',
            'status': 'received',
            'developer': DEVELOPER_NAME,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Contact form error: {e}")
        return jsonify({
            'message': 'Sorry, there was an error processing your message.',
            'status': 'error',
            'developer': DEVELOPER_NAME
        }), 500

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    return render_template('error.html', 
                         error_code=404, 
                         error_message="Page not found",
                         developer=DEVELOPER_NAME), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    logger.error(f"Internal server error: {error}")
    return render_template('error.html', 
                         error_code=500, 
                         error_message="Internal server error",
                         developer=DEVELOPER_NAME), 500

if __name__ == '__main__':
    # Get port from environment variable (Rahti sets this)
    port = int(os.environ.get('PORT', 8080))
    
    logger.info(f"Starting {DEVELOPER_NAME}'s Personal Web Application on port {port}")
    logger.info(f"Main API endpoint for identification: /api/name")
    logger.info(f"Developer: {DEVELOPER_NAME}")
    logger.info(f"Contact: {DEVELOPER_EMAIL}")
    
    # Run the application
    app.run(
        host='0.0.0.0',  # Important: bind to all interfaces for containers
        port=port,
        debug=app.config['DEBUG']
    )