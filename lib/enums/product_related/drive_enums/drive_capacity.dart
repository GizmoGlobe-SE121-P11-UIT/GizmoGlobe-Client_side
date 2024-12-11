enum DriveCapacity {
  gb256('256 GB'),
  gb512('512 GB'),
  tb1('1 TB'),
  tb2('2 TB'),
  tb4('4 TB');

  final String description;

  const DriveCapacity(this.description);

  @override
  String toString() {
    return description;
  }
}