import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../general/app_text_style.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class RangeFilter extends StatelessWidget {
  final String name;
  final TextEditingController fromController;
  final TextEditingController toController;
  final Function(String) onFromValueChanged;
  final Function(String) onToValueChanged;
  final String fromValue;
  final String toValue;

  const RangeFilter({
    super.key,
    required this.name,
    required this.fromController,
    required this.toController,
    required this.onFromValueChanged,
    required this.onToValueChanged,
    required this.fromValue,
    required this.toValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyle.biggerText.copyWith(
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
                    S.of(context).from,
                    style: AppTextStyle.subtitleText.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  FieldWithIcon(
                    controller: fromController,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: S.of(context).min,
                    onChanged: onFromValueChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
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
                    S.of(context).to,
                    style: AppTextStyle.subtitleText.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  FieldWithIcon(
                    controller: toController,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: S.of(context).max,
                    onChanged: onToValueChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
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
