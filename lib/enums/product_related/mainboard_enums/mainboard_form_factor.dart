enum MainboardFormFactor {
  unknown('Unknown'),
  atx('ATX'),
  microATX('Micro-ATX'),
  miniITX('Mini-ITX');

  final String description;

  const MainboardFormFactor(this.description);

  String getName() {
    return name;
  }

  static List<MainboardFormFactor> getValues() {
    return MainboardFormFactor.values
        .where((e) => e != MainboardFormFactor.unknown)
        .toList();
  }

  @override
  String toString() {
    return description;
  }
}

extension MainboardFormFactorExtension on MainboardFormFactor {
  static MainboardFormFactor fromName(String name) {
    // Normalize the input name
    final normalizedName = name.toLowerCase().trim();

    // Map Firebase/common format values to enum names
    final Map<String, String> firebaseToEnum = {
      'atx': 'atx',
      'micro-atx': 'microATX',
      'micro_atx': 'microATX',
      'microatx': 'microATX',
      'micro atx': 'microATX',
      'mini-itx': 'miniITX',
      'mini_itx': 'miniITX',
      'miniitx': 'miniITX',
      'mini itx': 'miniITX',
    };

    // Check if it's a Firebase/common format first
    final enumName = firebaseToEnum[normalizedName] ?? normalizedName;

    // First, try to match against description field (e.g., "Mini-ITX" from Firebase)
    final matchedByDescription = MainboardFormFactor.values.firstWhere(
      (e) => e.description.toLowerCase() == normalizedName,
      orElse: () => MainboardFormFactor.unknown,
    );

    if (matchedByDescription != MainboardFormFactor.unknown) {
      return matchedByDescription;
    }

    // Fall back to enum name matching
    return MainboardFormFactor.values.firstWhere(
      (e) => e.getName().toLowerCase() == enumName.toLowerCase(),
      orElse: () => MainboardFormFactor.unknown,
    );
  }
}
