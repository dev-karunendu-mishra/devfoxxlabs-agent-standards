import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic tokens that `ColorScheme` doesn't cover. Add domain status colors
/// (order/booking states) here rather than hardcoding them in widgets.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.surfaceSecondary,
    required this.borderSubtle,
    required this.textTertiary,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color surfaceSecondary;
  final Color borderSubtle;
  final Color textTertiary;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  static const light = AppThemeColors(
    surfaceSecondary: AppColors.lightSurfaceSecondary,
    borderSubtle: AppColors.lightBorderSubtle,
    textTertiary: AppColors.lightTextTertiary,
    success: AppColors.success,
    successContainer: AppColors.successLight,
    warning: AppColors.warning,
    warningContainer: AppColors.warningLight,
    info: AppColors.info,
    infoContainer: AppColors.infoLight,
  );

  static const dark = AppThemeColors(
    surfaceSecondary: AppColors.darkSurfaceSecondary,
    borderSubtle: AppColors.darkBorderSubtle,
    textTertiary: AppColors.darkTextTertiary,
    success: AppColors.success,
    successContainer: Color(0xFF064E3B),
    warning: AppColors.warning,
    warningContainer: Color(0xFF78350F),
    info: AppColors.info,
    infoContainer: Color(0xFF1E3A8A),
  );

  @override
  AppThemeColors copyWith({
    Color? surfaceSecondary,
    Color? borderSubtle,
    Color? textTertiary,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return AppThemeColors(
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
