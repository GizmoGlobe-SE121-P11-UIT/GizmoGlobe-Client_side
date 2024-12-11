enum CPUFamily {
  corei3Ultra3('Core i3 - Ultra 3'),
  corei5Ultra5('Core i5 - Ultra 5'),
  corei7Ultra7('Core i7 - Ultra 7'),
  xeon('Xeon'),
  ryzen3('Ryzen 3'),
  ryzen5('Ryzen 5'),
  ryzen7('Ryzen 7'),
  threadripper('Threadripper');

  final String description;

  const CPUFamily(this.description);

  @override
  String toString() {
    return description;
  }
}