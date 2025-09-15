import 'package:flutter/material.dart';

/// Helper class pour détecter le type d'appareil et adapter l'interface
class DeviceHelper {
  /// Détermine si l'appareil est une tablette basé sur la largeur d'écran
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  /// Détermine si l'appareil est une grande tablette
  static bool isLargeTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 900;
  }

  /// Détermine si l'appareil est un téléphone
  static bool isPhone(BuildContext context) {
    return !isTablet(context);
  }

  /// Retourne la hauteur optimale de l'AppBar selon le type d'appareil
  static double getAppBarHeight(BuildContext context) {
    if (isLargeTablet(context)) {
      return 64.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 10.0;
    }
  }

  /// Retourne le padding adaptatif selon le type d'appareil
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return const EdgeInsets.all(32.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// Retourne la taille de police adaptative
  static double getAdaptiveFontSize(
    BuildContext context, {
    double baseSize = 16.0,
  }) {
    if (isLargeTablet(context)) {
      return baseSize * 1.2;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize;
    }
  }

  /// Retourne le type d'appareil sous forme de string pour le debug
  static String getDeviceType(BuildContext context) {
    if (isLargeTablet(context)) {
      return 'Large Tablet';
    } else if (isTablet(context)) {
      return 'Tablet';
    } else {
      return 'Phone';
    }
  }
}
