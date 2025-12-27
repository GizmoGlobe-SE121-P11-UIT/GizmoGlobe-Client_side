enum DriveType {
  unknown('Unknown'),
  hdd('HDD'),
  sataSSD('SATA SSD'),
  m2NGFF('M2 NGFF'),
  m2NVME('M2 NVME');

  final String description;

  const DriveType(this.description);

  String getName() {
    return name;
  }

  static List<DriveType> getValues() {
    return DriveType.values.where((e) => e != DriveType.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }

  factory DriveType.fromJson(Map<String, dynamic> json) {
    String name = json['driveType'] ?? 'Unknown';
    return DriveTypeExtension.fromName(name);
  }
}

extension DriveTypeExtension on DriveType {
  static DriveType fromName(String name) {
    // Normalize the input name
    final normalizedName = name.toLowerCase().trim();

    // Map Firebase snake_case values to enum names
    final Map<String, String> firebaseToEnum = {
      'ssd_sata': 'sataSSD',
      'm2_ngff': 'm2NGFF',
      'm2_nvme': 'm2NVME',
      'hdd': 'hdd',
    };

    // Check if it's a Firebase format first
    final enumName = firebaseToEnum[normalizedName] ?? normalizedName;

    return DriveType.values.firstWhere(
        (e) => e.getName().toLowerCase() == enumName.toLowerCase(),
        orElse: () => DriveType.unknown);
  }
}
