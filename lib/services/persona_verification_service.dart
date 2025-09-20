import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class PersonaVerificationService {
  static final PersonaVerificationService _instance = PersonaVerificationService._internal();
  factory PersonaVerificationService() => _instance;
  PersonaVerificationService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Stream controller for verification completion events
  final StreamController<VerificationResult> _verificationController =
      StreamController<VerificationResult>.broadcast();

  Stream<VerificationResult> get verificationStream => _verificationController.stream;

  /// Initialize deep link listening
  Future<void> initialize() async {
    try {
      // Listen for incoming links when app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _handleIncomingLink,
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );

      // Handle link that launched the app (if any)
      try {
        final initialLink = await _appLinks.getInitialAppLink();
        if (initialLink != null) {
          _handleIncomingLink(initialLink);
        }
      } catch (e) {
        // getInitialAppLink might not be available in all versions
        debugPrint('Could not get initial app link: $e');
      }
    } catch (e) {
      debugPrint('Failed to initialize persona verification service: $e');
    }
  }

  /// Handle incoming deep links
  void _handleIncomingLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    if (uri.scheme == 'healthmapai' && uri.host == 'verification') {
      _handleVerificationCallback(uri);
    }
  }

  /// Parse verification callback parameters
  void _handleVerificationCallback(Uri uri) {
    try {
      final inquiryId = uri.queryParameters['inquiry-id'];
      final status = uri.queryParameters['status'];
      final sessionId = uri.queryParameters['session-id'];

      debugPrint('Verification callback - Status: $status, Inquiry ID: $inquiryId');

      final result = VerificationResult(
        inquiryId: inquiryId,
        status: _parseVerificationStatus(status),
        sessionId: sessionId,
        timestamp: DateTime.now(),
      );

      // Emit the verification result
      _verificationController.add(result);
    } catch (e) {
      debugPrint('Error parsing verification callback: $e');
      _verificationController.add(VerificationResult(
        inquiryId: null,
        status: VerificationStatus.error,
        sessionId: null,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
    }
  }

  /// Parse status string to enum
  VerificationStatus _parseVerificationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'approved':
        return VerificationStatus.completed;
      case 'declined':
      case 'rejected':
        return VerificationStatus.declined;
      case 'needs_review':
      case 'pending':
        return VerificationStatus.needsReview;
      case 'expired':
        return VerificationStatus.expired;
      default:
        return VerificationStatus.unknown;
    }
  }

  /// Dispose of resources
  void dispose() {
    _linkSubscription?.cancel();
    _verificationController.close();
  }
}

/// Verification result from WithPersona
class VerificationResult {
  final String? inquiryId;
  final VerificationStatus status;
  final String? sessionId;
  final DateTime timestamp;
  final String? error;

  VerificationResult({
    required this.inquiryId,
    required this.status,
    required this.sessionId,
    required this.timestamp,
    this.error,
  });

  bool get isSuccessful => status == VerificationStatus.completed;
  bool get isDeclined => status == VerificationStatus.declined;
  bool get needsReview => status == VerificationStatus.needsReview;
  bool get hasError => error != null || status == VerificationStatus.error;

  @override
  String toString() {
    return 'VerificationResult(inquiryId: $inquiryId, status: $status, sessionId: $sessionId, timestamp: $timestamp, error: $error)';
  }
}

/// Possible verification statuses
enum VerificationStatus {
  completed,
  declined,
  needsReview,
  expired,
  error,
  unknown,
}

extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.completed:
        return 'Verification Completed';
      case VerificationStatus.declined:
        return 'Verification Declined';
      case VerificationStatus.needsReview:
        return 'Under Review';
      case VerificationStatus.expired:
        return 'Verification Expired';
      case VerificationStatus.error:
        return 'Verification Error';
      case VerificationStatus.unknown:
        return 'Unknown Status';
    }
  }

  String get description {
    switch (this) {
      case VerificationStatus.completed:
        return 'Your identity has been successfully verified.';
      case VerificationStatus.declined:
        return 'Your verification was declined. Please try again or contact support.';
      case VerificationStatus.needsReview:
        return 'Your verification is under review. We\'ll notify you once complete.';
      case VerificationStatus.expired:
        return 'Your verification session has expired. Please start a new verification.';
      case VerificationStatus.error:
        return 'An error occurred during verification. Please try again.';
      case VerificationStatus.unknown:
        return 'Verification status is unknown. Please check back later.';
    }
  }
}