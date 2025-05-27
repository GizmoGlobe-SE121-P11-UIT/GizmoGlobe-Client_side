import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../objects/address_related/address.dart';
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
  final TextEditingController _receiverPhoneController =
      TextEditingController();
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
          title: GradientText(text: S.of(context).editAddress),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).receiverName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FieldWithIcon(
                        controller: _receiverNameController,
                        hintText: S.of(context).receiverName,
                        onChanged: (value) {
                          cubit.updateAddress(receiverName: value);
                        },
                        fillColor: Theme.of(context).colorScheme.surface,
                        textColor: Theme.of(context).colorScheme.onSurface,
                        hintTextColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).receiverPhone,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FieldWithIcon(
                        controller: _receiverPhoneController,
                        hintText: S.of(context).receiverPhone,
                        onChanged: (value) {
                          cubit.updateAddress(receiverPhone: value);
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.phone,
                        fillColor: Theme.of(context).colorScheme.surface,
                        textColor: Theme.of(context).colorScheme.onSurface,
                        hintTextColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).address,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                      Text(
                        S.of(context).streetAddress,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FieldWithIcon(
                        controller: _streetController,
                        hintText: S.of(context).streetAddress,
                        onChanged: (value) {
                          cubit.updateAddress(street: value);
                        },
                        fillColor: Theme.of(context).colorScheme.surface,
                        textColor: Theme.of(context).colorScheme.onSurface,
                        hintTextColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9\s,\-\./]')),
                        ],
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
                      cubit.updateAddress(hidden: true);
                      Navigator.of(context).pop(
                        cubit.getAddresses(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context).remove,
                          style: AppTextStyle.buttonTextBold,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        cubit.getAddresses(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_outlined),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context).save,
                          style: AppTextStyle.buttonTextBold,
                        ),
                      ],
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
