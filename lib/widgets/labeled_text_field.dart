import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Подписанное текстовое поле в едином стиле экрана «Вход/Регистрация»:
/// текст-лейбл сверху + скруглённое поле с иконкой и опциональной кнопкой
/// (например "глазок" показа пароля).
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final bool readOnly;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onTap: onTap,
            readOnly: readOnly,
            style: AppTextStyles.rowLabel,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.searchHint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              prefixIcon: leadingIcon == null
                  ? null
                  : Icon(leadingIcon, size: 20, color: AppColors.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 20),
              suffixIcon: trailing,
            ),
          ),
        ),
      ],
    );
  }
}
