import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Minimal, responsive bottom navigation shell.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final double height;
  final EdgeInsets margin;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 64,
    this.margin = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: Row(
                children: List.generate(
                  items.length,
                  (index) => Expanded(
                    child: _NavItem(
                      item: items[index],
                      isSelected: currentIndex == index,
                      onTap: () => onTap(index),
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? AppColors.textTertiary
        : AppColors.textTertiaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? AppColors.accentGold : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentGold : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
