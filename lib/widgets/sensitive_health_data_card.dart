import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/persona_verification_service.dart';

class SensitiveHealthDataCard extends StatefulWidget {
  const SensitiveHealthDataCard({Key? key}) : super(key: key);

  @override
  State<SensitiveHealthDataCard> createState() => _SensitiveHealthDataCardState();
}

class _SensitiveHealthDataCardState extends State<SensitiveHealthDataCard> {
  StreamSubscription<VerificationResult>? _verificationSubscription;
  VerificationResult? _lastVerificationResult;

  @override
  void initState() {
    super.initState();
    _listenForVerificationResults();
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    super.dispose();
  }

  void _listenForVerificationResults() {
    _verificationSubscription = PersonaVerificationService()
        .verificationStream
        .listen((result) {
      if (mounted) {
        setState(() {
          _lastVerificationResult = result;
        });
        _showVerificationResultDialog(result);
      }
    });
  }

  void _showVerificationResultDialog(VerificationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              result.isSuccessful
                  ? Icons.check_circle
                  : result.hasError
                      ? Icons.error
                      : Icons.info,
              color: result.isSuccessful
                  ? Colors.green
                  : result.hasError
                      ? Colors.red
                      : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(result.status.displayName),
          ],
        ),
        content: Text(result.status.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sensitive Health Data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Add verified health information to get more personalized recommendations for sensitive conditions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure ID verification powered by WithPersona',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_lastVerificationResult != null) ...[
              _buildVerificationStatusSection(),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _lastVerificationResult?.isSuccessful == true
                    ? null
                    : () => _launchPersonaVerification(context),
                icon: Icon(_lastVerificationResult?.isSuccessful == true
                    ? Icons.check_circle
                    : Icons.open_in_browser),
                label: Text(_lastVerificationResult?.isSuccessful == true
                    ? 'ID Verified'
                    : 'Verify ID with WithPersona'),
                style: FilledButton.styleFrom(
                  backgroundColor: _lastVerificationResult?.isSuccessful == true
                      ? Colors.green
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatusSection() {
    final result = _lastVerificationResult!;
    final statusColor = result.isSuccessful
        ? Colors.green
        : result.hasError
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            result.isSuccessful
                ? Icons.verified_user
                : result.hasError
                    ? Icons.error_outline
                    : Icons.info_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.status.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (result.inquiryId != null)
                  Text(
                    'ID: ${result.inquiryId!.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPersonaVerification(BuildContext context) async {
    try {
      // Get configuration from environment variables
      final templateId = dotenv.env['PERSONA_TEMPLATE_ID'] ?? '';
      final environment = dotenv.env['PERSONA_ENVIRONMENT'] ?? 'sandbox';

      if (templateId.isEmpty || templateId == 'your_template_id_here') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Persona template ID not configured. Please add your template ID to .env file.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Create the proper Persona hosted verification URL with redirect
      // Format includes redirect URI for deep linking back to app
      final redirectUri = Uri.encodeComponent('healthmapai://verification/complete');
      final personaUrl = 'https://withpersona.com/verify?inquiry-template-id=$templateId&environment=$environment&redirect-uri=$redirectUri';

      final Uri url = Uri.parse(personaUrl);

      // Force external browser to ensure verification opens outside the app
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Opening WithPersona ID verification...'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to open verification link. Please check your internet connection.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening verification: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}