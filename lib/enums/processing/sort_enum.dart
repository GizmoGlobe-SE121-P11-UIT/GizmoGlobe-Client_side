enum SortEnum {
  releaseLatest('Release date: Latest'),
  releaseOldest('Release date: Oldest'),
  salesHighest('Sale: Highest'),
  salesLowest('Sale: Lowest'),
  cheapest('Price: Cheapest'),
  expensive('Price: Expensive'),
  discountHighest('Discount: Highest'),
  discountLowest('Discount: Lowest');

  final String description;
  const SortEnum(this.description);

  @override
  String toString() {
    return description;
  }
}