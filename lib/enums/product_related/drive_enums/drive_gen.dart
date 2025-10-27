enum DriveGen {
  unknown(0, 'Unknown', 'Unknown'),
  gen3(3, 'Gen 3', 'III'),
  gen4(4, 'Gen 4', 'IV'),
  gen5(5, 'Gen 5', 'V');

  final int genNumber;
  final String description;
  final String romanNumeral;

  const DriveGen(this.genNumber, this.description, this.romanNumeral);

  int getNumber() => genNumber;

  static List<DriveGen> getValues() {
    return DriveGen.values.where((e) => e != DriveGen.unknown).toList();
  }

  @override
  String toString() => description;

  String toRoman() => romanNumeral;

  factory DriveGen.fromJson(dynamic json) {
    int? gen;
    if (json is int) {
      gen = json;
    } else if (json is Map<String, dynamic>) {
      gen = json['gen'] is int ? json['gen'] : int.tryParse(json['gen']?.toString() ?? '');
    }
    return DriveGenExtension.fromInt(gen ?? 0);
  }
}

extension DriveGenExtension on DriveGen {
  static DriveGen fromInt(int gen) {
    return DriveGen.values.firstWhere(
          (e) => e.genNumber == gen,
      orElse: () => DriveGen.unknown,
    );
  }
}
