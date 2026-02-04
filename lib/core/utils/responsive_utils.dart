import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  // static double getTableGridCrossAxisCount(BuildContext context) {
  //   final deviceType = getDeviceType(context);
  //   switch (deviceType) {
  //     case DeviceType.mobile:
  //       return 3;
  //     case DeviceType.tablet:
  //       return 6;
  //     case DeviceType.desktop:
  //       return 10;
  //   }
  // }

  // static double getMenuGridCrossAxisCount(BuildContext context) {
  //   final deviceType = getDeviceType(context);
  //   switch (deviceType) {
  //     case DeviceType.mobile:
  //       return 2;
  //     case DeviceType.tablet:
  //       return 3;
  //     case DeviceType.desktop:
  //       return 4;
  //   }
  // }

  // static EdgeInsets getScreenPadding(BuildContext context) {
  //   final deviceType = getDeviceType(context);
  //   switch (deviceType) {
  //     case DeviceType.mobile:
  //       return const EdgeInsets.all(12);
  //     case DeviceType.tablet:
  //       return const EdgeInsets.all(16);
  //     case DeviceType.desktop:
  //       return const EdgeInsets.all(24);
  //   }
  // }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);
        return builder(context, deviceType);
      },
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);
        switch (deviceType) {
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.mobile:
            return mobile;
        }
      },
    );
  }
}
