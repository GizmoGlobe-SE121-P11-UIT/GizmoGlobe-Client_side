enum SortEnum {
  releaseLatest('Release date: Latest'),
  releaseOldest('Release date: Oldest'),
  salesHighest('Sale: Highest'),
  salesLowest('Sale: Lowest'),
  priceLowest('Price: Lowest'),
  priceHighest('Price: Highest');

  final String description;
  const SortEnum(this.description);

  @override
  String toString() {
    return description;
  }
}