import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class FieldWithIcon extends StatelessWidget {
  final double height;
  final bool readOnly;
  final String hintText;
  final Color fillColor;
  final VoidCallback? onTap;
  final Icon? prefixIcon;
  final VoidCallback? onPrefixIconPressed;
  final Icon? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool obscureText;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final TextEditingController controller;
  final Color hintTextColor;
  final Color textColor;
  final FocusNode? focusNode;

  const FieldWithIcon({
    super.key,
    this.height = 45,
    this.readOnly = false,
    this.hintText = '',
    this.fillColor = Colors.transparent,
    this.onTap,
    this.prefixIcon,
    this.onPrefixIconPressed,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.inputFormatters,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.all(2),
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    required this.controller,
    this.hintTextColor = Colors.grey,
    this.textColor = Colors.white,
    this.focusNode,
  });

  String? getText() {
    return controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.08),
            //     blurRadius: 8,
            //     offset: Offset(0, 2),
            //   ),
            // ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: TextFormField(
            readOnly: readOnly,
            textAlignVertical: TextAlignVertical.center,
            onTap: onTap,
            onFieldSubmitted: onSubmitted,
            onChanged: onChanged,
            controller: controller,
            textInputAction: TextInputAction.done,
            focusNode: focusNode,
            decoration: InputDecoration(
              filled: true,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: hintText,
              hintStyle: TextStyle(
                color: hintTextColor,
                fontFamily: 'Montserrat',
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
              prefixIcon: prefixIcon != null
                  ? InkWell(
                      onTap: onPrefixIconPressed,
                      child: prefixIcon,
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? InkWell(
                      onTap: onSuffixIconPressed,
                      child: suffixIcon,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  vertical: (height - fontSize) / 2, horizontal: 8),
            ),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters ??
                [FilteringTextInputFormatter.allow(RegExp(r'.*'))],
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
              fontFamily: 'Montserrat',
            ),
            obscureText: obscureText,
          ),
        ),
      ],
    );
  }
}
