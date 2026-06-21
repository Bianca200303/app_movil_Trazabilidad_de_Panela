/// Centralized font size configuration for the entire app.
///
/// This class provides a single source of truth for all font sizes in the application.
/// All sizes follow a consistent +2px increment pattern for better hierarchy.
///
/// To scale all fonts across the app:
/// 1. Change the [scaleFactor] value (e.g., 1.0 = 100%, 1.1 = 110%, 0.9 = 90%)
/// 2. Recompile the app
///
/// Note: Currently using constant scaling. For runtime-adjustable font sizes,
/// implement a FontScaleProvider using Riverpod in the future.
class FontSizeConfig {
  /// Global scale factor for all font sizes
  /// Adjust this single value to scale all fonts proportionally
  /// 1.0 = 100% (normal), 1.1 = 110%, 0.9 = 90%, etc.
  static const double scaleFactor = 1.1;

  // ============================================================================
  // Base semantic sizes following +2px increment pattern
  // ============================================================================

  /// Smallest text for captions and very secondary information (14px)
  static const double captionSize = 14 * scaleFactor;

  /// Small text for input labels and secondary labels (16px)
  static const double smallSize = 16 * scaleFactor;

  /// Base text size for body content and main labels (18px)
  static const double baseSize = 18 * scaleFactor;

  /// Large text for prominent body content (20px)
  static const double largeSize = 20 * scaleFactor;

  /// Card titles and smaller section headers (24px)
  static const double cardTitleSize = 24 * scaleFactor;

  /// Section titles and major headings (28px)
  static const double sectionTitleSize = 28 * scaleFactor;

  /// Main page titles and primary headings (36px)
  static const double mainTitleSize = 36 * scaleFactor;
}
