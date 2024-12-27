import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/checkbox_button.dart';

class OptionFilter<T> extends StatelessWidget {
  final String name;
  final List<T> enumValues;
  final List<T> selectedValues;
  final void Function(T value) onToggleSelection;

  const OptionFilter({
    super.key,
    required this.name,
    required this.enumValues,
    required this.selectedValues,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final int itemCount = enumValues.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyle.buttonTextBold,
        ),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: List.generate(itemCount + (itemCount % 2), (index) {
            if (index < itemCount) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: CheckboxButton(
                  text: enumValues[index].toString(),
                  isSelected: selectedValues.contains(enumValues[index]),
                  onSelected: () {
                    onToggleSelection(enumValues[index]);
                  },
                ),
              );
            } else {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
              );
            }
          }),
        ),
      ],
    );
  }
}