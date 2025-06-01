import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

/// A reusable scaffold that properly handles consistent app bar styling and navigation
/// with proper spacing regardless of entry point (drawer or direct navigation)
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.centerTitle = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: automaticallyImplyLeading
            ? null
            : showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
        actions: actions,
        // The key to fixing the overlap is ensuring consistent system UI overlay style
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      drawer: drawer,
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}