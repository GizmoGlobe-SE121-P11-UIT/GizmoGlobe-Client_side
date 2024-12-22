import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class GradientDropdown<T> extends StatelessWidget {
  final List<T> Function(String filter, dynamic infiniteScrollProps) items;
  final bool Function(T? d1, T? d2) compareFn;
  final String Function(T d) itemAsString;
  final void Function(T? d) onChanged;
  final T? selectedItem;
  final String hintText;
  final double fontSize;

  const GradientDropdown({
    super.key,
    required this.items,
    required this.compareFn,
    required this.itemAsString,
    required this.onChanged,
    required this.selectedItem,
    this.hintText = '',
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 2,
          style: BorderStyle.solid,
          color: Colors.transparent,
        ),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: DropdownSearch<T>(
          items: items,
          compareFn: compareFn,
          itemAsString: itemAsString,
          dropdownBuilder: (context, selectedItem) => _customDropdownBuilder(context, selectedItem?.toString() ?? ''),
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
                hintText: 'Search',
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
              border: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            textAlignVertical: TextAlignVertical.center,
          ),
          onChanged: onChanged,
          selectedItem: selectedItem,
        ),
      ),
    );
  }

  Widget _customDropdownBuilder(BuildContext context, String text) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Montserrat',
          fontSize: fontSize,
        ),
      ),
    );
  }
}