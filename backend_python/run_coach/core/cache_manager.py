"""
Cache manager for Run Coach to improve performance
"""
import json
import time
from typing import Dict, Any, Optional
import hashlib

class CacheManager:
    """Simple in-memory cache for Run Coach API responses"""
    
    def __init__(self, ttl_seconds: int = 300):
        self._cache: Dict[str, Dict[str, Any]] = {}
        self.ttl_seconds = ttl_seconds
    
    def _get_cache_key(self, endpoint: str, params: Dict[str, Any]) -> str:
        """Generate cache key from endpoint and parameters"""
        # Sort params for consistent key generation
        sorted_params = json.dumps(params, sort_keys=True)
        key_string = f"{endpoint}:{sorted_params}"
        return hashlib.md5(key_string.encode()).hexdigest()
    
    def get(self, endpoint: str, params: Dict[str, Any]) -> Optional[Any]:
        """Get cached response if available and not expired"""
        key = self._get_cache_key(endpoint, params)
        
        if key in self._cache:
            cached = self._cache[key]
            if time.time() < cached['expires_at']:
                return cached['data']
            else:
                # Remove expired entry
                del self._cache[key]
        
        return None
    
    def set(self, endpoint: str, params: Dict[str, Any], data: Any):
        """Cache response with TTL"""
        key = self._get_cache_key(endpoint, params)
        self._cache[key] = {
            'data': data,
            'expires_at': time.time() + self.ttl_seconds
        }
    
    def clear(self):
        """Clear all cached data"""
        self._cache.clear()
    
    def clean_expired(self):
        """Remove expired entries"""
        current_time = time.time()
        expired_keys = [
            key for key, value in self._cache.items()
            if current_time >= value['expires_at']
        ]
        for key in expired_keys:
            del self._cache[key]

# Global cache instance
cache = CacheManager(ttl_seconds=300)  # 5 minutes cache