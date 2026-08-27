import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Reusable visual primitives for the customer-facing Premium UI.
/// Business logic stays outside these widgets.
class PremiumUI {
  PremiumUI._();

  static const double radiusCard = 20;
  static const double radiusControl = 14;
  static const double controlHeight = 48;
  static const double pagePadding = 18;
  static const double sectionGap = 24;

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0F1A1A1A),
    blurRadius: 24,
    offset: Offset(0, 4),
  );
}

class PremiumPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const PremiumPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
          );

    final button = SizedBox(
      height: PremiumUI.controlHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceMuted,
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumUI.radiusControl),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
        child: child,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class PremiumSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PremiumSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PremiumUI.controlHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PremiumUI.radiusControl),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
    );
  }
}

class PremiumSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final surface = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(PremiumUI.radiusCard),
        boxShadow: const [PremiumUI.cardShadow],
      ),
      child: content,
    );

    if (onTap == null) return surface;
    return Material(color: Colors.transparent, child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PremiumUI.radiusCard),
      child: surface,
    ));
  }
}

class PremiumBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool accent;

  const PremiumBadge({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? AppColors.cream : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: AppColors.accent), const SizedBox(width: 4)],
          Text(label, style: AppTextStyles.badgeLabel),
        ],
      ),
    );
  }
}

class PremiumSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onScan;

  const PremiumSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A1A1A1A), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onScan != null)
                IconButton(onPressed: onScan, icon: const Icon(Icons.qr_code_scanner_outlined)),
              if (onClear != null)
                IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
