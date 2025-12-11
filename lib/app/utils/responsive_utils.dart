import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Device type based on screen width
enum DeviceType { phone, tablet, desktop }

/// Responsive utilities for handling different screen sizes
/// Uses actual device dimensions instead of hardcoded values
class ResponsiveUtils {
  /// Get device type based on shortest side (handles orientation)
  static DeviceType getDeviceType(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide >= 900) return DeviceType.desktop;
    if (shortestSide >= 600) return DeviceType.tablet;
    return DeviceType.phone;
  }

  /// Check if device is a tablet or larger
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) != DeviceType.phone;
  }

  /// Check if device is a small phone (height < 700)
  static bool isSmallPhone(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height < 700;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value based on device type
  static T value<T>(BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.phone:
        return phone;
    }
  }

  /// Get max content width - uses percentage of screen width
  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        // Use 70% of screen width on desktop
        return width * 0.7;
      case DeviceType.tablet:
        // Use full width on tablet (let it breathe)
        return double.infinity;
      case DeviceType.phone:
        return double.infinity;
    }
  }

  /// Get horizontal padding based on screen width
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return width * 0.08; // 8% of screen width
      case DeviceType.tablet:
        return width * 0.05; // 5% of screen width
      case DeviceType.phone:
        return 20.w;
    }
  }

  /// Get scaled font size based on screen size
  static double scaledFontSize(double baseSize, BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    // Scale based on shortest side relative to phone baseline (375)
    final scaleFactor = math.min(shortestSide / 375, 1.5);
    return baseSize * scaleFactor;
  }

  /// Get scaled icon size based on screen size
  static double scaledIconSize(double baseSize, BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    // Scale based on shortest side relative to phone baseline (375)
    final scaleFactor = math.min(shortestSide / 375, 1.6);
    return baseSize * scaleFactor;
  }

  /// Get mic button size based on screen dimensions
  static double micButtonSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    // Base size is ~27% of shortest side, clamped between 90 and 180
    final size = shortestSide * 0.18;
    return size.clamp(90.0, 180.0);
  }
}

/// Extension for responsive sizing
extension ResponsiveExtension on num {
  /// Responsive width based on screen dimensions
  double rw(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final scaleFactor = shortestSide / 375;
    return toDouble() * scaleFactor;
  }

  /// Responsive height based on screen dimensions
  double rh(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final scaleFactor = height / 812;
    return toDouble() * scaleFactor;
  }

  /// Responsive font size based on screen dimensions
  double rsp(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final scaleFactor = math.min(shortestSide / 375, 1.4);
    return toDouble() * scaleFactor;
  }
}

/// A wrapper widget that provides responsive layout for different screen sizes
/// Returns child as-is for both phone and tablet (full screen experience)
class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  /// Background widget to show behind the content on tablet
  final Widget? tabletBackground;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.tabletBackground,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);

    if (!isTablet || tabletBackground == null) {
      // Phone or no background: return child as-is
      return child;
    }

    // Tablet with background
    return Stack(
      children: [
        tabletBackground!,
        child,
      ],
    );
  }
}

/// A scaffold wrapper that provides tablet-optimized layout
/// Uses full screen with appropriate padding for tablets
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;

  /// Whether to show a card-like container on tablet (default: false for full tablet experience)
  final bool showCardOnTablet;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.showCardOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF0a0520);

    // Both phone and tablet use full screen - tablet just has more space
    return Scaffold(
      backgroundColor: bgColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

