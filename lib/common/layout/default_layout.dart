import 'package:flutter/material.dart';

class DefaultLayout extends StatelessWidget {
  const DefaultLayout({
    super.key,
    required this.child,
    this.backgroundColor,
    this.title,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.centerTitle = true,
    this.appBarColor,
    this.actions,
    this.leading,
    this.elevation = 0,
    this.foregroundColor,
  });

  final Color? backgroundColor;
  final Widget child;
  final String? title;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final Color? appBarColor;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: backgroundColor ?? Colors.white,
        appBar: renderAppBar(),
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  AppBar? renderAppBar() {
    if (title == null) return null;

    return AppBar(
      backgroundColor: appBarColor ?? const Color(0xFFF4F6FF),
      elevation: elevation,
      leading: leading,
      title: Text(
        title!,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? Colors.black,
        ),
      ),
      centerTitle: centerTitle,
      foregroundColor: Colors.black,
      actions: actions,
    );
  }
}
