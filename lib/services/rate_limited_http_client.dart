import 'dart:math';

class RateLimitedHttpClient {
  static const int _maxRetries = 3;
  static const int _baseDelayMs = 1000; // 1 second base delay
  static const int _maxDelayMs = 30000; // 30 seconds max delay
  
  // Track last request time per endpoint to implement client-side rate limiting
  static final Map<String, DateTime> _lastRequestTimes = {};
  static const int _minRequestIntervalMs = 1000; // Minimum 1 second between requests
  
  /// Makes an HTTP request with rate limiting, retry logic, and exponential backoff
  static Future<T> makeRequest<T>(
    String endpoint,
    Future<T> Function() requestFunction, {
    int maxRetries = _maxRetries,
    bool enableClientRateLimit = true,
  }) async {
    // Client-side rate limiting
    if (enableClientRateLimit) {
      await _enforceClientRateLimit(endpoint);
    }
    
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final result = await requestFunction();
        
        // Reset rate limit tracking on successful request
        _lastRequestTimes[endpoint] = DateTime.now();
        
        return result;
      } catch (e) {
        attempt++;
        
        if (_isRateLimitError(e) && attempt < maxRetries) {
          final delay = _calculateBackoffDelay(attempt);
          print('Rate limit hit for $endpoint. Retrying in ${delay}ms (attempt $attempt/$maxRetries)');
          await Future.delayed(Duration(milliseconds: delay));
          continue;
        }
        
        // If it's not a rate limit error or we've exhausted retries, rethrow
        rethrow;
      }
    }
    
    throw Exception('Maximum retry attempts exceeded for $endpoint');
  }
  
  /// Check if the error is a rate limiting error
  static bool _isRateLimitError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('too many requests') ||
           errorString.contains('rate limit') ||
           errorString.contains('429') ||
           errorString.contains('quota exceeded');
  }
  
  /// Calculate exponential backoff delay with jitter
  static int _calculateBackoffDelay(int attempt) {
    final exponentialDelay = _baseDelayMs * pow(2, attempt - 1);
    final jitter = Random().nextInt(_baseDelayMs ~/ 2); // Add some randomness
    final totalDelay = (exponentialDelay + jitter).round();
    
    return totalDelay.clamp(_baseDelayMs, _maxDelayMs);
  }
  
  /// Enforce client-side rate limiting
  static Future<void> _enforceClientRateLimit(String endpoint) async {
    final lastRequestTime = _lastRequestTimes[endpoint];
    
    if (lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequestTime).inMilliseconds;
      
      if (timeSinceLastRequest < _minRequestIntervalMs) {
        final waitTime = _minRequestIntervalMs - timeSinceLastRequest;
        print('Client-side rate limiting: waiting ${waitTime}ms for $endpoint');
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }
  }
  
  /// Get a user-friendly error message for rate limiting
  static String getRateLimitErrorMessage(dynamic error) {
    if (_isRateLimitError(error)) {
      return 'Server is busy. Please wait a moment and try again.';
    }
    return error.toString();
  }
  
  /// Clear rate limit tracking (useful for testing or reset)
  static void clearRateLimitTracking() {
    _lastRequestTimes.clear();
  }
}