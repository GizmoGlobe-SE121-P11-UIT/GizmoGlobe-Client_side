import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiFieldWithIcon extends StatelessWidget {
  final String hintText;
  final Color fillColor;
  final Icon? prefixIcon;
  final double borderRadius;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double fontSize;
  final FontWeight fontWeight;
  final int? maxLines;
  final Function(String)? onSubmitted;
  final Function(String)? onChange;
  final TextEditingController? controller;

  const MultiFieldWithIcon({
    super.key,
    this.hintText = '',
    this.fillColor = Colors.white,
    this.prefixIcon,
    this.borderRadius = 15,
    this.keyboardType,
    this.inputFormatters,
    this.fontSize = 20,
    this.fontWeight = FontWeight.normal,
    this.maxLines,
    this.onSubmitted,
    this.onChange,
    this.controller,
  });

  String? getText() {
    return controller?.text;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            alignment: Alignment.topCenter,
            width: 38,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                bottomLeft: Radius.circular(borderRadius),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: fontSize,
                left: 16,
              ),
              child: prefixIcon,
            ),
          ),

          Expanded(
            child: TextFormField(
              maxLines: maxLines,
              textAlignVertical: TextAlignVertical.center,
              onFieldSubmitted: onSubmitted,
              textInputAction: TextInputAction.done,
              controller: controller,
              onChanged: onChange,
              decoration: InputDecoration(
                filled: true,
                isDense: true,
                fillColor: fillColor,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
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
          ),
        ],
      ),
    );
  }
}