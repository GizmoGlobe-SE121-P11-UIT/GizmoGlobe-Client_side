import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../data/database/database.dart';
import '../../../objects/address_related/district.dart';
import '../../../objects/address_related/province.dart';
import '../../../objects/address_related/ward.dart';

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
          DropdownButton<Province>(
            isExpanded: true,
            underline: widget.underline,
            hint: Text(
              'Choose Province',
              style: const TextStyle().merge(widget.placeHolderTextStyle),
            ),
            value: _provinceSelected,
            items: Database().provinceList.map((province) {
              return DropdownMenuItem<Province>(
                value: province,
                child: widget.buildItem != null ? widget.buildItem!(province.fullNameEn) : Text(province.fullNameEn),
              );
            }).toList(),
            onChanged: (province) {
              setState(() {
                _provinceSelected = province;
                _districtSelected = null;
                _wardsSelected = null;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, null, null);
            },
          ),

          DropdownButton<District>(
            isExpanded: true,
            underline: widget.underline,
            hint: Text(
              'Choose District',
              style: const TextStyle().merge(widget.placeHolderTextStyle),
            ),
            value: _districtSelected,
            items: (_provinceSelected?.districts ?? []).map<DropdownMenuItem<District>>((d) {
              return DropdownMenuItem<District>(
                value: d,
                child: widget.buildItem != null ? widget.buildItem!(d.fullNameEn) : Text(d.fullNameEn),
              );
            }).toList(),
            onChanged: (d) {
              setState(() {
                _districtSelected = d;
                _wardsSelected = null;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, _districtSelected?.fullNameEn, null);
            },
          ),

          DropdownButton<Ward>(
            isExpanded: true,
            underline: widget.underline,
            hint: Text(
              'Choose Ward',
              style: const TextStyle().merge(widget.placeHolderTextStyle),
            ),
            value: _wardsSelected,
            items: (_districtSelected?.wards ?? []).map<DropdownMenuItem<Ward>>((w) {
              return DropdownMenuItem<Ward>(
                value: w,
                child: widget.buildItem != null ? widget.buildItem!(w.fullNameEn) : Text(w.fullNameEn),
              );
            }).toList(),
            onChanged: (w) {
              setState(() {
                _wardsSelected = w;
              });
              widget.onAddressChanged?.call(_provinceSelected?.fullNameEn, _districtSelected?.fullNameEn, _wardsSelected?.fullNameEn);
            },
          ),
        ],
      ),
    );
  }
}