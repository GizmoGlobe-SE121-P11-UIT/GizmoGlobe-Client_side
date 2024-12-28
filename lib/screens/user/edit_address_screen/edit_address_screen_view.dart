import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import '../../../widgets/general/gradient_checkbox.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import 'edit_address_screen_cubit.dart';
import '../../../widgets/general/address_picker.dart';

class EditAddressScreen extends StatefulWidget {
  final Address address;

  const EditAddressScreen({super.key, required this.address});

  static Widget newInstance(Address address) => BlocProvider(
    create: (context) => EditAddressScreenCubit(),
    child: EditAddressScreen(address: address),
  );

  @override
  State<EditAddressScreen> createState() => _EditAddressScreen();
}

class _EditAddressScreen extends State<EditAddressScreen> {
  EditAddressScreenCubit get cubit => context.read<EditAddressScreenCubit>();

  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cubit.initialize(widget.address);
    _receiverNameController.text = widget.address.receiverName;
    _receiverPhoneController.text = widget.address.receiverPhone;
    _streetController.text = widget.address.street ?? '';
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () {
              Navigator.pop(context);
            },
            fillColor: Colors.transparent,
          ),
          title: const GradientText(text: 'Edit Address'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FieldWithIcon(
                        controller: _receiverNameController,
                        hintText: 'Receiver Name',
                        onChanged: (value) {
                          cubit.updateAddress(receiverName: value);
                        },
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      const SizedBox(height: 8),
                    
                      FieldWithIcon(
                        controller: _receiverPhoneController,
                        hintText: 'Receiver Phone',
                        onChanged: (value) {
                          cubit.updateAddress(receiverPhone: value);
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.phone,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      const SizedBox(height: 8),
                    
                      AddressPicker(
                        provinceSelected: widget.address.province,
                        districtSelected: widget.address.district,
                        wardSelected: widget.address.ward,
                        onAddressChanged: (province, district, ward) {
                          cubit.updateAddress(
                            province: province,
                            district: district,
                            ward: ward,
                          );
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 8),
                    
                      FieldWithIcon(
                        controller: _streetController,
                        hintText: 'Street name, building, house no.',
                        onChanged: (value) {
                          cubit.updateAddress(street: value);
                        },
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        cubit.getAddresses(),
                      );
                    },
                    child: Text('Save',
                      style: AppTextStyle.buttonTextBold.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      cubit.updateAddress(hidden: true);
                      Navigator.of(context).pop(
                        cubit.getAddresses(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                    ),
                    child: Text('Delete',
                      style: AppTextStyle.buttonTextBold.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}