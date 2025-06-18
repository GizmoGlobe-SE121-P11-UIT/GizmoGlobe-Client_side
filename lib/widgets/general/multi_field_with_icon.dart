import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';

/// A multiline text input field with optional prefix and suffix icons
/// Extends the functionality of FieldWithIcon but for multiline text input
class MultiFieldWithIcon extends StatelessWidget {
  final double minHeight;
  final int maxLines;
  final bool readOnly;
  final String hintText;
  final String? labelText;
  final Color? fillColor;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final VoidCallback? onPrefixIconPressed;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius borderRadius;
  final bool obscureText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final TextEditingController controller;
  final Color? hintTextColor;
  final Color? textColor;
  final FocusNode? focusNode;
  final bool isEnabled;

  const MultiFieldWithIcon({
    super.key,
    this.minHeight = 100,
    this.maxLines = 5,
    this.readOnly = false,
    this.hintText = '',
    this.labelText,
    this.fillColor,
    this.onTap,
    this.prefixIcon,
    this.onPrefixIconPressed,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.multiline,
    this.inputFormatters,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    required this.controller,
    this.hintTextColor,
    this.textColor,
    this.focusNode,
    this.isEnabled = true,
  });

  String? getText() {
    return controller.text;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveFillColor = fillColor ?? colorScheme.surface;
    final effectiveTextColor = textColor ?? colorScheme.onSurface;
    final effectiveHintTextColor =
        hintTextColor ?? colorScheme.onSurfaceVariant;
    final borderSide =
    BorderSide(color: colorScheme.outlineVariant, width: 1.2);
    final focusBorderSide = BorderSide(color: colorScheme.primary, width: 1.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(labelText!, style: AppTextStyle.smallText),
          ),
        Container(
          constraints: BoxConstraints(
            minHeight: minHeight,
          ),
          child: TextFormField(
            enabled: isEnabled,
            readOnly: readOnly,
            maxLines: maxLines,
            minLines: 3,
            textAlignVertical: TextAlignVertical.top,
            onTap: onTap,
            onFieldSubmitted: onSubmitted,
            onChanged: onChanged,
            controller: controller,
            style: TextStyle(
              color: effectiveTextColor,
              fontFamily: 'Montserrat',
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
            keyboardType: keyboardType ?? TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            focusNode: focusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: effectiveFillColor,
              hintText: hintText,
              hintStyle: TextStyle(
                color: effectiveHintTextColor,
                fontFamily: 'Montserrat',
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: prefixIcon != null
                  ? InkWell(
                onTap: onPrefixIconPressed,
                child: Icon(prefixIcon),
              )
                  : null,
              suffixIcon: suffixIcon != null
                  ? InkWell(
                onTap: onSuffixIconPressed,
                child: Icon(suffixIcon),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5), width: 1.2),
              ),
            ),
            obscureText: obscureText,
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }
}
