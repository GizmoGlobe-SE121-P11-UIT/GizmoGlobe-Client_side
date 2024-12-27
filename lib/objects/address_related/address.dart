import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/address_related/district.dart';
import 'package:gizmoglobe_client/objects/address_related/province.dart';
import 'package:gizmoglobe_client/objects/address_related/ward.dart';

class Address {
  String? addressID;
  String customerID;
  String receiverName;
  String receiverPhone;
  Province? province;
  District? district;
  Ward? ward;
  String? street;

  Address({
    this.addressID,
    required this.customerID,
    required this.receiverName,
    required this.receiverPhone,
    this.province,
    this.district,
    this.ward,
    this.street,
  });

  @override
  String toString() {
    return '$receiverName - $receiverPhone'
        '${street != null ? ', $street' : ''}'
        '${ward != null ? ', $ward' : ''}'
        '${district != null ? ', $district' : ''}'
        '${province != null ? ', $province' : ''}';
  }

  static Address nullAddress = Address(
    customerID: '',
    receiverName: '',
    receiverPhone: '',
  );

  Map<String, dynamic> toMap() {
    return {
      'AddressID': addressID,
      'CustomerID': customerID,
      'ReceiverName': receiverName,
      'ReceiverPhone': receiverPhone,
      'ProvinceCode': province?.code,
      'DistrictCode': district?.code,
      'WardCode': ward?.code,
      'Street': street,
    };
  }

  static Address fromMap(Map<String, dynamic> map) {
    final province = Database().provinceList.firstWhere((p) => p.code == map['provinceCode'], orElse: () => Province.nullProvince);
    final district = province.districts?.firstWhere((d) => d.code == map['districtCode'], orElse: () => District.nullDistrict) ?? District.nullDistrict;
    final ward = district.wards?.firstWhere((w) => w.code == map['wardCode'], orElse: () => Ward.nullWard) ?? Ward.nullWard;

    return Address(
      addressID: map['addressID'],
      customerID: map['customerID'],
      receiverName: map['receiverName'],
      receiverPhone: map['receiverPhone'],
      province: province,
      district: district,
      ward: ward,
      street: map['street'],
    );
  }
}