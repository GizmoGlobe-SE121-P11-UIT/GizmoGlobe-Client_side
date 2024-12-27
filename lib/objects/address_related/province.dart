import 'package:gizmoglobe_client/objects/address_related/district.dart';

class Province {
  final String code;
  final String name;
  final String nameEn;
  final String fullName;
  final String fullNameEn;
  final String codeName;
  final int administrativeRegionId;
  final String administrativeRegionName;
  final String administrativeRegionNameEn;
  final int administrativeUnitId;
  final String administrativeUnitShortName;
  final String administrativeUnitFullName;
  final String administrativeUnitShortNameEn;
  final String administrativeUnitFullNameEn;
  final List<District>? districts;

  Province({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.fullName,
    required this.fullNameEn,
    required this.codeName,
    required this.administrativeRegionId,
    required this.administrativeRegionName,
    required this.administrativeRegionNameEn,
    required this.administrativeUnitId,
    required this.administrativeUnitShortName,
    required this.administrativeUnitFullName,
    required this.administrativeUnitShortNameEn,
    required this.administrativeUnitFullNameEn,
    this.districts,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['Code'],
      name: json['Name'],
      nameEn: json['NameEn'],
      fullName: json['FullName'],
      fullNameEn: json['FullNameEn'],
      codeName: json['CodeName'],
      administrativeRegionId: json['AdministrativeRegionId'],
      administrativeRegionName: json['AdministrativeRegionName'],
      administrativeRegionNameEn: json['AdministrativeRegionNameEn'],
      administrativeUnitId: json['AdministrativeUnitId'],
      administrativeUnitShortName: json['AdministrativeUnitShortName'],
      administrativeUnitFullName: json['AdministrativeUnitFullName'],
      administrativeUnitShortNameEn: json['AdministrativeUnitShortNameEn'],
      administrativeUnitFullNameEn: json['AdministrativeUnitFullNameEn'],
      districts: json['District'] == null ? <District>[] : (json['District'] as List<dynamic>)
              .map((d) => District.fromJson(d))
              .toList(),
    );
  }

  @override
  String toString() {
    return fullNameEn;
  }
}