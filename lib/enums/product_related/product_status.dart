import 'package:flutter/material.dart';

enum ProductStatusEnum {
  active,
  inactive,
  outOfStock,
  discontinued;

  String getName() {
    switch (this) {
      case ProductStatusEnum.active:
        return 'active';
      case ProductStatusEnum.inactive:
        return 'inactive';
      case ProductStatusEnum.outOfStock:
        return 'outOfStock';
      case ProductStatusEnum.discontinued:
        return 'discontinued';
    }
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case ProductStatusEnum.active:
        return 'Active';
      case ProductStatusEnum.inactive:
        return 'Inactive';
      case ProductStatusEnum.outOfStock:
        return 'Out of Stock';
      case ProductStatusEnum.discontinued:
        return 'Discontinued';
    }
  }

  Color getColor() {
    switch (this) {
      case ProductStatusEnum.active:
        return Colors.green;
      case ProductStatusEnum.inactive:
        return Colors.grey;
      case ProductStatusEnum.outOfStock:
        return Colors.orange;
      case ProductStatusEnum.discontinued:
        return Colors.red;
    }
  }
}
