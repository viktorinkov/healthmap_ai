#!/usr/bin/env python3
"""
Health Map AI Performance Monitor
Monitors memory usage, database connections, and response times
"""

import psutil
import time
import logging
import requests
import psycopg2
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# Configuration
MONITOR_INTERVAL = 30  # seconds
API_BASE_URL = "http://localhost:5001"
LOG_FILE = "performance_monitor.log"

# Database config
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'health_monitoring'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'port': int(os.getenv('DB_PORT', 5432))
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_system_metrics():
    """Get system performance metrics"""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        memory_used_gb = memory.used / (1024**3)
        memory_total_gb = memory.total / (1024**3)
        
        # Find Python processes
        python_processes = []
        for proc in psutil.process_iter(['pid', 'name', 'memory_percent', 'cpu_percent']):
            try:
                if 'python' in proc.info['name'].lower():
                    python_processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        return {
            'cpu_percent': cpu_percent,
            'memory_percent': memory_percent,
            'memory_used_gb': round(memory_used_gb, 2),
            'memory_total_gb': round(memory_total_gb, 2),
            'python_processes': python_processes
        }
    except Exception as e:
        logger.error(f"Error getting system metrics: {e}")
        return {}

def test_database_connection():
    """Test database connection and get connection count"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        with conn.cursor() as cursor:
            # Get active connection count
            cursor.execute("""
                SELECT count(*) 
                FROM pg_stat_activity 
                WHERE state = 'active' AND datname = %s
            """, (DB_CONFIG['database'],))
            
            active_connections = cursor.fetchone()[0]
            
        conn.close()
        return {'status': 'healthy', 'active_connections': active_connections}
    except Exception as e:
        return {'status': 'error', 'error': str(e)}

def test_api_endpoints():
    """Test critical API endpoints"""
    endpoints = [
        '/api/health-check',
    ]
    
    results = {}
    for endpoint in endpoints:
        try:
            start_time = time.time()
            response = requests.get(f"{API_BASE_URL}{endpoint}", timeout=10)
            response_time = time.time() - start_time
            
            results[endpoint] = {
                'status_code': response.status_code,
                'response_time_ms': round(response_time * 1000, 2),
                'status': 'healthy' if response.status_code == 200 else 'error'
            }
        except Exception as e:
            results[endpoint] = {
                'status': 'error',
                'error': str(e),
                'response_time_ms': None
            }
    
    return results

def main():
    """Main monitoring loop"""
    logger.info("Starting Health Map AI Performance Monitor")
    
    while True:
        try:
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Get metrics
            system_metrics = get_system_metrics()
            db_status = test_database_connection()
            api_status = test_api_endpoints()
            
            # Log summary
            logger.info(f"=== Performance Report - {timestamp} ===")
            
            if system_metrics:
                logger.info(f"CPU: {system_metrics['cpu_percent']}%")
                logger.info(f"Memory: {system_metrics['memory_percent']}% "
                           f"({system_metrics['memory_used_gb']}/{system_metrics['memory_total_gb']} GB)")
                
                # Log Python process info
                for proc in system_metrics['python_processes']:
                    logger.info(f"Python PID {proc['pid']}: "
                               f"CPU {proc['cpu_percent']}%, "
                               f"Memory {proc['memory_percent']}%")
            
            # Database status
            if db_status['status'] == 'healthy':
                logger.info(f"Database: Healthy ({db_status['active_connections']} active connections)")
            else:
                logger.error(f"Database: Error - {db_status.get('error', 'Unknown')}")
            
            # API status
            for endpoint, status in api_status.items():
                if status['status'] == 'healthy':
                    logger.info(f"API {endpoint}: {status['response_time_ms']}ms")
                else:
                    logger.error(f"API {endpoint}: Error - {status.get('error', 'Unknown')}")
            
            # Warning thresholds
            if system_metrics.get('memory_percent', 0) > 80:
                logger.warning("⚠️ HIGH MEMORY USAGE detected!")
            
            if system_metrics.get('cpu_percent', 0) > 80:
                logger.warning("⚠️ HIGH CPU USAGE detected!")
            
            logger.info("=" * 50)
            
        except Exception as e:
            logger.error(f"Monitoring error: {e}")
        
        time.sleep(MONITOR_INTERVAL)

if __name__ == "__main__":
    main()