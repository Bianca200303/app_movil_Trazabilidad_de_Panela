import 'package:flutter/material.dart';

/// Utility class for handling responsive screen sizes and breakpoints
class ScreenUtils {
  /// Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Small screen thresholds for mobile devices
  static const double smallScreenHeight = 700;
  static const double smallScreenWidth = 400;

  /// Very small screen thresholds (gama baja: 360 dp de ancho o menos, o
  /// pantallas muy bajas). Debe ser más estricto que "small".
  static const double verySmallScreenHeight = 640;
  static const double verySmallScreenWidth = 361;

  /// Ancho desde el cual dos botones caben lado a lado sin cortar el texto.
  static const double sideBySideButtonsWidth = 400;

  /// Get screen size from context
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return getScreenSize(context).width < mobileBreakpoint;
  }

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = getScreenSize(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context).width >= desktopBreakpoint;
  }

  /// Check if current screen is considered small (for mobile devices)
  static bool isSmallScreen(BuildContext context) {
    final size = getScreenSize(context);
    return size.height < smallScreenHeight || size.width < smallScreenWidth;
  }

  /// Check if current screen is very small (needs extra compact layout)
  static bool isVerySmallScreen(BuildContext context) {
    final size = getScreenSize(context);
    return size.height < verySmallScreenHeight || size.width < verySmallScreenWidth;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isVerySmallScreen(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isSmallScreen(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive horizontal padding for cards and forms
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isVerySmallScreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 12.0);
    } else if (isSmallScreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  /// Get responsive card width based on screen size
  static double getResponsiveCardWidth(BuildContext context) {
    // En celulares la tarjeta ocupa todo el ancho: los márgenes ya los pone
    // el padding horizontal de la pantalla (sumar un porcentaje encima
    // restaba ancho útil a los campos en pantallas angostas).
    if (isMobile(context)) return double.infinity;
    return 400.0; // Fixed width for larger screens
  }

  /// Check if buttons should be stacked vertically instead of horizontally
  static bool shouldStackButtons(BuildContext context) {
    return getScreenSize(context).width < sideBySideButtonsWidth;
  }

  /// Factor de tamaño de letra según la pantalla. Los tamaños base
  /// (FontSizeConfig) están pensados para celulares de ~412 dp o más; en
  /// pantallas más angostas o muy bajas se reducen para que quepa más
  /// contenido con menos scroll. Se aplica una sola vez, en la raíz de la app
  /// (ResponsiveTextScale), encima del tamaño de letra que el usuario haya
  /// elegido en su celular.
  static double getResponsiveFontScale(BuildContext context) {
    final size = getScreenSize(context);
    final byWidth = size.width < verySmallScreenWidth
        ? 0.82
        : size.width < smallScreenWidth
            ? 0.88
            : size.width < mobileBreakpoint
                ? 0.94
                : 1.0;
    final isShort = size.height < verySmallScreenHeight;
    return isShort && byWidth > 0.88 ? 0.88 : byWidth;
  }

  /// Get responsive spacing between form elements
  static double getResponsiveSpacing(BuildContext context) {
    if (isVerySmallScreen(context)) {
      return 12.0;
    } else if (isSmallScreen(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }
}

/// Extension on BuildContext for easier access to screen utilities
extension ScreenUtilsExtension on BuildContext {
  /// Get screen size
  Size get screenSize => ScreenUtils.getScreenSize(this);
  
  /// Check if mobile
  bool get isMobile => ScreenUtils.isMobile(this);
  
  /// Check if tablet
  bool get isTablet => ScreenUtils.isTablet(this);
  
  /// Check if desktop
  bool get isDesktop => ScreenUtils.isDesktop(this);
  
  /// Check if small screen
  bool get isSmallScreen => ScreenUtils.isSmallScreen(this);
  
  /// Check if very small screen
  bool get isVerySmallScreen => ScreenUtils.isVerySmallScreen(this);
  
  /// Get responsive padding
  EdgeInsets get responsivePadding => ScreenUtils.getResponsivePadding(this);
  
  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding => ScreenUtils.getResponsiveHorizontalPadding(this);
  
  /// Get responsive card width
  double get responsiveCardWidth => ScreenUtils.getResponsiveCardWidth(this);
  
  /// Check if buttons should be stacked
  bool get shouldStackButtons => ScreenUtils.shouldStackButtons(this);
  
  /// Get responsive font scale
  double get responsiveFontScale => ScreenUtils.getResponsiveFontScale(this);
  
  /// Get responsive spacing
  double get responsiveSpacing => ScreenUtils.getResponsiveSpacing(this);
}