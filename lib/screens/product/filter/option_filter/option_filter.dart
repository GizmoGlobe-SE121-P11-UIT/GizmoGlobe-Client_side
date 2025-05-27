import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
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

  String _getLocalizedText(BuildContext context, String text) {
    switch (text) {
      // PSU Modular
      case 'FULL_MODULAR':
        return S.of(context).fullModular;
      case 'SEMI_MODULAR':
        return S.of(context).semiModular;
      case 'NON_MODULAR':
        return S.of(context).nonModular;

      // RAM Type
      case 'DDR3':
        return S.of(context).ddr3;
      case 'DDR4':
        return S.of(context).ddr4;
      case 'DDR5':
        return S.of(context).ddr5;

      // Drive Type
      case 'HDD':
        return S.of(context).hdd;
      case 'SSD':
        return S.of(context).ssd;
      case 'NVME':
        return S.of(context).nvme;

      // Mainboard Form Factor
      case 'ATX':
        return S.of(context).atx;
      case 'MICRO_ATX':
        return S.of(context).microAtx;
      case 'MINI_ITX':
        return S.of(context).miniItx;
      case 'EATX':
        return S.of(context).eAtx;

      default:
        return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = enumValues.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20.0,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: List.generate(itemCount + (itemCount % 2), (index) {
            if (index < itemCount) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: CheckboxButton(
                  text:
                      _getLocalizedText(context, enumValues[index].toString()),
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
