import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class GradientDropdown<T> extends StatelessWidget {
  final List<T> Function(String filter, dynamic infiniteScrollProps) items;
  final bool Function(T? d1, T? d2) compareFn;
  final String Function(T d) itemAsString;
  final void Function(T? d) onChanged;
  final T? selectedItem;
  final String hintText;
  final double fontSize;
  final Widget Function(BuildContext context, T? selectedItem)? dropdownBuilder;

  const GradientDropdown({
    super.key,
    required this.items,
    required this.compareFn,
    required this.itemAsString,
    required this.onChanged,
    required this.selectedItem,
    this.hintText = '',
    this.fontSize = 16,
    this.dropdownBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: DropdownSearch<T>(
        items: items,
        compareFn: compareFn,
        itemAsString: itemAsString,
        dropdownBuilder: dropdownBuilder ?? _defaultDropdownBuilder,
        suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
            iconClosed: const Icon(Icons.keyboard_arrow_down),
            iconOpened: const Icon(Icons.keyboard_arrow_up),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              filled: false,
              hintText: S.of(context).search,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey,
              fontFamily: 'Montserrat',
              fontSize: fontSize,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            fillColor: Colors.transparent,
          ),
          textAlignVertical: TextAlignVertical.center,
        ),
        onChanged: onChanged,
        selectedItem: selectedItem,
      ),
    );
  }

  Widget _defaultDropdownBuilder(BuildContext context, T? item) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Text(
        item != null ? itemAsString(item) : hintText,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Montserrat',
          fontSize: fontSize,
        ),
      ),
    );
  }
}
