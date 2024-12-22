import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../data/database/database.dart';
import '../../objects/address_related/district.dart';
import '../../objects/address_related/province.dart';
import '../../objects/address_related/ward.dart';
import 'gradient_dropdown.dart';

class AddressPicker extends StatefulWidget {
  final Widget Function(String? text)? buildItem;
  final Widget? underline;
  final EdgeInsets? insidePadding;
  final TextStyle? placeHolderTextStyle;
  final Function(String? province, String? district, String? ward)? onAddressChanged;

  const AddressPicker({
    super.key,
    this.buildItem,
    this.underline,
    this.insidePadding,
    this.placeHolderTextStyle,
    this.onAddressChanged,
  });

  @override
  State createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  Province? _provinceSelected;
  District? _districtSelected;
  Ward? _wardsSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GradientDropdown<Province>(
            items: (filter, infiniteScrollProps) => Database().provinceList,
            compareFn: (Province? p1, Province? p2) => p1?.code == p2?.code,
            itemAsString: (Province p) => p.fullNameEn,
            onChanged: (province) {
              setState(() {
                _provinceSelected = province;
                _districtSelected = null;
                _wardsSelected = null;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, null, null);
            },
            selectedItem: _provinceSelected,
            hintText: 'Choose Province',
          ),
          const SizedBox(height: 8),
          GradientDropdown<District>(
            items: (filter, infiniteScrollProps) => _provinceSelected?.districts ?? [],
            compareFn: (District? d1, District? d2) => d1?.code == d2?.code,
            itemAsString: (District d) => d.fullNameEn,
            onChanged: (district) {
              setState(() {
                _districtSelected = district;
                _wardsSelected = null;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, _districtSelected?.fullNameEn, null);
            },
            selectedItem: _districtSelected,
            hintText: 'Choose District',
          ),
          const SizedBox(height: 8),
          GradientDropdown<Ward>(
            items: (filter, infiniteScrollProps) => _districtSelected?.wards ?? [],
            compareFn: (Ward? w1, Ward? w2) => w1?.code == w2?.code,
            itemAsString: (Ward w) => w.fullNameEn,
            onChanged: (ward) {
              setState(() {
                _wardsSelected = ward;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, _districtSelected?.fullNameEn, _wardsSelected?.fullNameEn);
            },
            selectedItem: _wardsSelected,
            hintText: 'Choose Ward',
          ),
        ],
      ),
    );
  }
}