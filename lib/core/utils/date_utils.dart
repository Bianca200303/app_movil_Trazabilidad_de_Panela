import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _ddMMYYYYFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Parses a date string in DD/MM/YYYY format to DateTime
  static DateTime? parseDDMMYYYY(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      return _ddMMYYYYFormat.parse(dateString);
    } catch (e) {
      // Try alternative parsing if the format doesn't match
      try {
        // Handle edge cases like single digit day/month
        return _ddMMYYYYFormat.parseLoose(dateString);
      } catch (e) {
        return null;
      }
    }
  }

  /// Formats a DateTime to DD/MM/YYYY string
  static String formatDDMMYYYY(DateTime date) {
    return _ddMMYYYYFormat.format(date);
  }

  /// Converts DD/MM/YYYY string to ISO date string (YYYY-MM-DD)
  static String? ddMMYYYYToISO(String dateString) {
    final date = parseDDMMYYYY(dateString);
    return date != null ? _isoFormat.format(date) : null;
  }

  /// Converts DateTime to ISO date string (YYYY-MM-DD)
  static String dateToISO(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Formats DateTime for display in Spanish format
  static String formatForDisplay(DateTime date) {
    final dayFormat = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es');
    return dayFormat.format(date);
  }

  /// Validates if a string is a valid DD/MM/YYYY date
  static bool isValidDDMMYYYY(String dateString) {
    return parseDDMMYYYY(dateString) != null;
  }

  /// Gets current date in DD/MM/YYYY format
  static String getCurrentDDMMYYYY() {
    return formatDDMMYYYY(DateTime.now());
  }

  /// Gets current date in ISO format
  static String getCurrentISO() {
    return dateToISO(DateTime.now());
  }
}