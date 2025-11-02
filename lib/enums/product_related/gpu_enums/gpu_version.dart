enum GPUVersion {
  unknown('Unknown'),
  gddr4('GDDR4'),
  gddr5('GDDR5'),
  gddr5x('GDDR5X'),
  gddr6('GDDR6'),
  gddr6x('GDDR6X'),
  gddr7('GDDR7'),
  gddr7x('GDDR7X');

  final String description;

  const GPUVersion(this.description);

  String getName() {
    return name;
  }

  static List<GPUVersion> getValues() {
    return GPUVersion.values.where((e) => e != GPUVersion.unknown).toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension GPUVersionExtension on GPUVersion {
  static GPUVersion fromName(String name) {
    return GPUVersion.values.firstWhere(
      (e) => e.getName() == name,
      orElse: () => GPUVersion.unknown,
    );
  }
}