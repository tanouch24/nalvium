import 'package:flutter/foundation.dart';

/// Prevents a release build from silently targeting a local development API.
class ReleaseConfig {
  static const apiUrl = String.fromEnvironment(
    'NALVIUM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static void validate() {
    if (!kReleaseMode) return;
    final local = apiUrl.contains('localhost') ||
        apiUrl.contains('127.0.0.1') ||
        apiUrl.contains('10.0.2.2') ||
        RegExp(r'https?://192\.168\.').hasMatch(apiUrl);
    if (local || !apiUrl.startsWith('https://')) {
      throw StateError(
        'Release configuration requires an HTTPS NALVIUM_API_URL.',
      );
    }
  }
}
