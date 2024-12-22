import 'package:gizmoglobe_client/objects/address_related/ward.dart';

class District {
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
  final List<Ward>? wards;

  District({
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
    this.wards,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
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
      wards: json['Ward'] == null ? <Ward>[] : (json['Ward'] as List<dynamic>)
              .map((w) => Ward.fromJson(w))
              .toList(),
    );
  }

  @override
  String toString() {
    return fullNameEn;
  }
}