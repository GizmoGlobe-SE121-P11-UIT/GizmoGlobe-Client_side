import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/general/checkbox_button.dart';

class ManufacturerFilter extends StatelessWidget {
  final List<Manufacturer> selectedManufacturers;
  final List<Manufacturer> manufacturerList;
  final void Function(Manufacturer manufacturer) onToggleSelection;

  const ManufacturerFilter({
    super.key,
    required this.selectedManufacturers,
    required this.manufacturerList,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // On web, use the available maxWidth to compute two fixed columns.
      // On mobile, keep prior behavior using screen width.
      final double containerWidth =
          kIsWeb ? constraints.maxWidth : MediaQuery.of(context).size.width;
      final double itemWidth =
          kIsWeb ? (containerWidth - 16) / 2 : (containerWidth - 48) / 2;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).manufacturer,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: manufacturerList.map((manufacturer) {
              return SizedBox(
                width: itemWidth,
                child: CheckboxButton(
                  text: manufacturer.manufacturerName,
                  isSelected: selectedManufacturers.contains(manufacturer),
                  onSelected: () {
                    onToggleSelection(manufacturer);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
