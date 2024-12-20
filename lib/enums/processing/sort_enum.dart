enum SortEnum {
  bestSeller('Best seller'),
  lowestPrice('Lowest price'),
  highestPrice('Highest price');

  final String description;
  const SortEnum(this.description);

  @override
  String toString() {
    return description;
  }
}