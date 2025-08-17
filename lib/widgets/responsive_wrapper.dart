import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A responsive wrapper that centers content and limits width on web/desktop
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 750.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on web or desktop
    final isWebOrDesktop = kIsWeb || 
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    if (isWebOrDesktop) {
      return Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
          child: child,
        ),
      );
    }

    // On mobile, return the child as-is
    return child;
  }
}

/// A responsive AppBar that constrains width on web/desktop
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  final double maxWidth;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.maxWidth = 750.0,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on web or desktop
    final isWebOrDesktop = kIsWeb || 
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    final appBar = AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: isWebOrDesktop, // Center title on web for better look
    );

    if (isWebOrDesktop) {
      return PreferredSize(
        preferredSize: preferredSize,
        child: Container(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: appBar,
            ),
          ),
        ),
      );
    }

    // On mobile, return the AppBar as-is
    return appBar;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
}

/// A responsive scaffold that automatically wraps the body and appBar with ResponsiveWrapper
class ResponsiveScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final double maxWidth;

  const ResponsiveScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.maxWidth = 750.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body != null 
          ? ResponsiveWrapper(
              maxWidth: maxWidth,
              child: body!,
            )
          : null,
    );
  }
}