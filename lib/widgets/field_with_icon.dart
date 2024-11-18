import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FieldWithIcon extends StatelessWidget {
  final bool readOnly;
  final String hintText;
  final Color fillColor;
  final VoidCallback? onTap;
  final Icon? prefixIcon;
  final VoidCallback? onPrefixIconPressed;
  final Icon? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final OutlineInputBorder? border;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double fontSize;
  final FontWeight fontWeight;
  final Function(String)? onSubmitted;
  final Function(String)? onChange;
  final TextEditingController controller;

  const FieldWithIcon({
    super.key,
    this.readOnly = false,
    this.hintText = '',
    this.fillColor = Colors.white,
    this.onTap,
    this.prefixIcon,
    this.onPrefixIconPressed,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.border,
    this.keyboardType,
    this.inputFormatters,
    this.fontSize = 20,
    this.fontWeight = FontWeight.normal,
    this.onSubmitted,
    this.onChange,
    required this.controller,
  });

  String? getText() {
    return controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: TextFormField(
        readOnly: readOnly,
        textAlignVertical: TextAlignVertical.center,
        onTap: onTap,
        onFieldSubmitted: onSubmitted,
        onChanged: onChange,
        controller: controller,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: fillColor,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: prefixIcon != null ? InkWell(
            onTap: onPrefixIconPressed,
            child: prefixIcon,
          )
              : null,
          suffixIcon: suffixIcon != null ? InkWell(
            onTap: onSuffixIconPressed,
            child: suffixIcon,
          )
              : null,
          border: border ?? OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}