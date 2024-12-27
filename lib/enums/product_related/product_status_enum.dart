enum ProductStatusEnum {
  active('Active'),
  outOfStock('Out of Stock'),
  discontinued('Discontinued');

  final String description;

  const ProductStatusEnum(this.description);

  String getName() {
    return name;
  }

  @override
  String toString() {
    return description;
  }
}

extension ProductStatusEnumExtension on ProductStatusEnum {
  static ProductStatusEnum fromName(String name) {
    return ProductStatusEnum.values.firstWhere((e) => e.getName() == name);
  }
}