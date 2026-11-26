import 'package:flutter/foundation.dart';

/// Logs a diagnostic message in debug and profile builds only.
///
/// Release builds stay silent: `debugPrint` alone would still reach the
/// device log there, and messages can include track titles and file URIs.
void logDebug(String message) {
  if (kReleaseMode) return;
  debugPrint(message);
}
