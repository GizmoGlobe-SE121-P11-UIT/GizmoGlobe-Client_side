import 'package:flutter/foundation.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';

class DrawerState {
  final bool isOpen;
  final List<CategoryEnum> categories;

  DrawerState({
    this.isOpen = false,
    this.categories = CategoryEnum.values,
  });

  DrawerState copyWith({
    bool? isOpen,
    List<CategoryEnum>? categories,
    String? username
  }) {
    return DrawerState(
      isOpen: isOpen ?? this.isOpen,
      categories: categories ?? this.categories,
    );
  }
}