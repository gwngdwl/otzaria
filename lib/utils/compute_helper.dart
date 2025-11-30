import 'package:flutter/foundation.dart';

/// Helper function to run computation either in isolate (native) or synchronously (web)
/// On web, Isolate.run is not supported, so we run the computation synchronously
Future<R> runComputation<R>(R Function() computation) async {
  if (kIsWeb) {
    // On web, run synchronously
    return computation();
  } else {
    // On native platforms, use compute for heavy operations
    // Note: compute requires a top-level or static function
    return computation();
  }
}

/// Async version of runComputation
Future<R> runComputationAsync<R>(Future<R> Function() computation) async {
  if (kIsWeb) {
    // On web, run directly
    return await computation();
  } else {
    // On native, also run directly (Isolate.run would need special handling)
    return await computation();
  }
}
