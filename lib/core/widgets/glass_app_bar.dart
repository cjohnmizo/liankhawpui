import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Glass App Bar
/// Compatibility app bar rendered in a minimal style.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;

  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
        elevation: elevation,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Glass Sliver App Bar
/// For use in CustomScrollView with blur effect
class GlassSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;

  const GlassSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.flexibleSpace,
    this.expandedHeight = 200,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      flexibleSpace: flexibleSpace != null
          ? Container(child: flexibleSpace)
          : null,
    );
  }
}
