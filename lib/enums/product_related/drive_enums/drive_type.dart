enum DriveType {
  hdd('HDD'),
  sataSSD('SATA SSD'),
  m2NGFF('M2 NGFF'),
  m2NVME('M2 NVME');

  final String description;

  const DriveType(this.description);

  @override
  String toString() {
    return description;
  }
}