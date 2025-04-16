import 'package:flutter/material.dart';

import '../../data/database/database.dart';
import '../../objects/address_related/district.dart';
import '../../objects/address_related/province.dart';
import '../../objects/address_related/ward.dart';
import '../../generated/l10n.dart';
import 'gradient_dropdown.dart';

class AddressPicker extends StatefulWidget {
  final Function(Province? province, District? district, Ward? ward)?
      onAddressChanged;
  final Province? provinceSelected;
  final District? districtSelected;
  final Ward? wardSelected;

  const AddressPicker({
    super.key,
    this.onAddressChanged,
    this.provinceSelected,
    this.districtSelected,
    this.wardSelected,
  });

  @override
  State createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  Province? _provinceSelected;
  District? _districtSelected;
  Ward? _wardSelected;

  @override
  void initState() {
    super.initState();
    _provinceSelected = widget.provinceSelected;
    _districtSelected = widget.districtSelected;
    _wardSelected = widget.wardSelected;
  }

  String _getLocalizedName(BuildContext context,
      {required String fullNameEn, required String fullName}) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'en' ? fullNameEn : fullName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        GradientDropdown<Province>(
          items: (String filter, dynamic props) => Database().provinceList,
          compareFn: (Province? p1, Province? p2) => p1?.code == p2?.code,
          itemAsString: (Province p) => _getLocalizedName(
            context,
            fullNameEn: p.fullNameEn,
            fullName: p.fullName,
          ),
          onChanged: (province) {
            setState(() {
              _provinceSelected = province;
              _districtSelected = null;
              _wardSelected = null;
            });
            widget.onAddressChanged?.call(_provinceSelected, null, null);
          },
          selectedItem: _provinceSelected,
          hintText: S.of(context).chooseProvince,
        ),
        const SizedBox(height: 8),
        GradientDropdown<District>(
          items: (String filter, dynamic props) =>
              _provinceSelected?.districts ?? [],
          compareFn: (District? d1, District? d2) => d1?.code == d2?.code,
          itemAsString: (District d) => _getLocalizedName(
            context,
            fullNameEn: d.fullNameEn,
            fullName: d.fullName,
          ),
          onChanged: (district) {
            setState(() {
              _districtSelected = district;
              _wardSelected = null;
            });
            widget.onAddressChanged
                ?.call(_provinceSelected, _districtSelected, null);
          },
          selectedItem: _districtSelected,
          hintText: S.of(context).chooseDistrict,
        ),
        const SizedBox(height: 8),
        GradientDropdown<Ward>(
          items: (String filter, dynamic props) =>
              _districtSelected?.wards ?? [],
          compareFn: (Ward? w1, Ward? w2) => w1?.code == w2?.code,
          itemAsString: (Ward w) => _getLocalizedName(
            context,
            fullNameEn: w.fullNameEn,
            fullName: w.fullName,
          ),
          onChanged: (ward) {
            setState(() {
              _wardSelected = ward;
            });
            widget.onAddressChanged
                ?.call(_provinceSelected, _districtSelected, _wardSelected);
          },
          selectedItem: _wardSelected,
          hintText: S.of(context).chooseWard,
        ),
      ],
    );
  }
}
