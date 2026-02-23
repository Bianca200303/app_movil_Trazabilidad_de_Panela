import 'package:flutter/foundation.dart';

/// Debug logging system for offline operations
///
/// Provides structured logging with timestamps, log levels, and module context.
/// All logs are printed to console with a consistent format for easy filtering.
class DebugLogger {
  /// Enable/disable logging globally
  static bool _enabled = true;

  /// Enable logging
  static void enable() => _enabled = true;

  /// Disable logging
  static void disable() => _enabled = false;

  /// Check if logging is enabled
  static bool get isEnabled => _enabled;

  /// Log debug message
  ///
  /// Use for detailed debugging information during development
  static void debug(String module, String method, String message) {
    _log(LogLevel.debug, module, method, message);
  }

  /// Log info message
  ///
  /// Use for general informational messages about normal operations
  static void info(String module, String method, String message) {
    _log(LogLevel.info, module, method, message);
  }

  /// Log warning message
  ///
  /// Use for potentially harmful situations that don't stop execution
  static void warning(String module, String method, String message) {
    _log(LogLevel.warning, module, method, message);
  }

  /// Log error message with optional stack trace
  ///
  /// Use for error events that might still allow the app to continue running
  static void error(
    String module,
    String method,
    String message, {
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, module, method, message);
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String module,
    String method,
    String message,
  ) {
    if (!_enabled || !kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);

    debugPrint('[$timestamp] [$levelStr] [$module.$method] $message');
  }
}

/// Log levels for debug logger
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
