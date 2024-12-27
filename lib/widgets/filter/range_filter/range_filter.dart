import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../general/app_text_style.dart';

class RangeFilter extends StatelessWidget {
  final String name;
  final ValueChanged<String> onFromValueChanged;
  final ValueChanged<String> onToValueChanged;
  final String fromValue;
  final String toValue;
  final TextEditingController fromController;
  final TextEditingController toController;

  const RangeFilter({
    super.key,
    required this.name,
    required this.onFromValueChanged,
    required this.onToValueChanged,
    required this.fromValue,
    required this.toValue,
    required this.fromController,
    required this.toController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyle.bigText.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From',
                    style: AppTextStyle.subtitleText.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  FieldWithIcon(
                    controller: fromController,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: 'Min',
                    onChanged: onFromValueChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To',
                    style: AppTextStyle.subtitleText.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  FieldWithIcon(
                    controller: toController,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: 'Max',
                    onChanged: onToValueChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}