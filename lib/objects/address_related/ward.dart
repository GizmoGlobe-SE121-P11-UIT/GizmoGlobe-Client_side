class Ward {
  final String code;
  final String name;
  final String nameEn;
  final String fullName;
  final String fullNameEn;
  final String codeName;
  final int administrativeUnitId;
  final String administrativeUnitShortName;
  final String administrativeUnitFullName;
  final String administrativeUnitShortNameEn;
  final String administrativeUnitFullNameEn;

  Ward({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.fullName,
    required this.fullNameEn,
    required this.codeName,
    required this.administrativeUnitId,
    required this.administrativeUnitShortName,
    required this.administrativeUnitFullName,
    required this.administrativeUnitShortNameEn,
    required this.administrativeUnitFullNameEn,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['Code'],
      name: json['Name'],
      nameEn: json['NameEn'],
      fullName: json['FullName'],
      fullNameEn: json['FullNameEn'],
      codeName: json['CodeName'],
      administrativeUnitId: json['AdministrativeUnitId'],
      administrativeUnitShortName: json['AdministrativeUnitShortName'],
      administrativeUnitFullName: json['AdministrativeUnitFullName'],
      administrativeUnitShortNameEn: json['AdministrativeUnitShortNameEn'],
      administrativeUnitFullNameEn: json['AdministrativeUnitFullNameEn'],
    );
  }

  static Ward nullWard = Ward(
    code: '',
    name: '',
    nameEn: '',
    fullName: '',
    fullNameEn: '',
    codeName: '',
    administrativeUnitId: 0,
    administrativeUnitShortName: '',
    administrativeUnitFullName: '',
    administrativeUnitShortNameEn: '',
    administrativeUnitFullNameEn: '',
  );

  @override
  String toString() {
    return fullNameEn;
  }
}