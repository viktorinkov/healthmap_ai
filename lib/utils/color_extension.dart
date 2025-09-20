import 'package:flutter/material.dart';

// Extension to handle the withValues call that might be used in the codebase
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return this.withOpacity(alpha ?? 1.0);
  }
}
