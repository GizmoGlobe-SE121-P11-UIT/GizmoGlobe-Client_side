import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:flutter/widgets.dart';

enum CategoryEnum {
  empty(''),
  ram('RAM'),
  cpu('CPU'),
  psu('PSU'),
  gpu('GPU'),
  drive('Drive'),
  mainboard('Mainboard');

  final String description;

  const CategoryEnum(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }

  static List<CategoryEnum> getValues() {
    return CategoryEnum.values.where((e) => e != CategoryEnum.empty).toList();
  }

  String getLocalizedDescription(BuildContext context) {
    switch (this) {
      case CategoryEnum.ram:
        return 'RAM';
      case CategoryEnum.cpu:
        return 'CPU';
      case CategoryEnum.psu:
        return 'PSU';
      case CategoryEnum.gpu:
        return 'GPU';
      case CategoryEnum.drive:
        return S.of(context).drive;
      case CategoryEnum.mainboard:
        return S.of(context).mainboard;
      default:
        return '';
    }
  }
}

extension CategoryEnumExtension on CategoryEnum {
  static CategoryEnum fromName(String name) {
    return CategoryEnum.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CategoryEnum.empty,
    );
  }
}
