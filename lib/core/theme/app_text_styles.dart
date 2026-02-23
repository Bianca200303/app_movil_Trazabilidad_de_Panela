import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/font_size_config.dart';

class AppTextStyles {
  // Titles - cleaner, less bold approach
  static const TextStyle mainTitle = TextStyle(
    fontSize: FontSizeConfig.mainTitleSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: FontSizeConfig.sectionTitleSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: FontSizeConfig.cardTitleSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Labels - simpler, more readable
  static const TextStyle fieldLabel = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // Body text - optimized for readability
  static const TextStyle bodyText = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyTextSmall = TextStyle(
    fontSize: FontSizeConfig.smallSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyTextLarge = TextStyle(
    fontSize: FontSizeConfig.largeSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Button text - clean and readable
  static const TextStyle buttonText = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonTextMedium = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.25,
  );

  // Special styles - minimal and clean
  static TextStyle topLabel = TextStyle(
    color: AppColors.labelTransparent,
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Additional styles for special cases
  static const TextStyle captionText = TextStyle(
    fontSize: FontSizeConfig.captionSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: FontSizeConfig.smallSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle linkText = TextStyle(
    color: AppColors.primary,
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w500,
  );

  // Input field styles
  static const TextStyle inputText = TextStyle(
    fontSize: FontSizeConfig.baseSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: FontSizeConfig.smallSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}