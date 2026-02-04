import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/responsive_utils.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? sidebar;
  final Widget? rightPanel;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final double sidebarWidth;
  final double rightPanelWidth;
  final bool showSidebar;
  final bool showRightPanel;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.sidebar,
    this.rightPanel,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.sidebarWidth = 280,
    this.rightPanelWidth = 350,
    this.showSidebar = true,
    this.showRightPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return Scaffold(
          appBar: appBar,
          backgroundColor: backgroundColor ?? AppColors.scaffoldBackground,
          bottomNavigationBar: deviceType.isMobile ? bottomNavigationBar : null,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          body: _buildBody(deviceType),
        );
      },
    );
  }

  Widget _buildBody(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return _buildDesktopLayout();
      case DeviceType.tablet:
        return _buildTabletLayout();
      case DeviceType.mobile:
        return body;
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        if (sidebar != null && showSidebar)
          SizedBox(
            width: sidebarWidth,
            child: sidebar,
          ),
        Expanded(child: body),
        if (rightPanel != null && showRightPanel)
          SizedBox(
            width: rightPanelWidth,
            child: rightPanel,
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        if (sidebar != null && showSidebar)
          SizedBox(
            width: sidebarWidth * 0.8,
            child: sidebar,
          ),
        Expanded(child: body),
      ],
    );
  }
}

class SidePanel extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const SidePanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.width,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: showBorder
            ? const Border(
                right: BorderSide(color: AppColors.divider),
              )
            : null,
      ),
      child: child,
    );
  }
}

class RightPanel extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const RightPanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.width,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: showBorder
            ? const Border(
                left: BorderSide(color: AppColors.divider),
              )
            : null,
      ),
      child: child,
    );
  }
}
