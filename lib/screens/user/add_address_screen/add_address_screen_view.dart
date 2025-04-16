import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import 'add_address_screen_cubit.dart';
import '../../../widgets/general/address_picker.dart';
import '../../../generated/l10n.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => AddAddressScreenCubit(),
        child: const AddAddressScreen(),
      );

  @override
  State<AddAddressScreen> createState() => _AddAddressScreen();
}

class _AddAddressScreen extends State<AddAddressScreen> {
  AddAddressScreenCubit get cubit => context.read<AddAddressScreenCubit>();

  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _streetController = TextEditingController();

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
          title: GradientText(text: S.of(context).addAddress),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  Address(
                    customerID: Database().userID,
                    receiverName: cubit.state.receiverName,
                    receiverPhone: cubit.state.receiverPhone,
                    province: cubit.state.province,
                    district: cubit.state.district,
                    ward: cubit.state.ward,
                    street: cubit.state.street,
                  ),
                );
              },
              child: Text(S.of(context).ok,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  hintTextColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),
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
                  hintTextColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
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
                  onAddressChanged: (province, district, ward) {
                    cubit.updateAddress(
                      province: province,
                      district: district,
                      ward: ward,
                    );
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 16),
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
                  hintTextColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\s,\-\./]')),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        Address(
                          customerID: Database().userID,
                          receiverName: cubit.state.receiverName,
                          receiverPhone: cubit.state.receiverPhone,
                          province: cubit.state.province,
                          district: cubit.state.district,
                          ward: cubit.state.ward,
                          street: cubit.state.street,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      S.of(context).save,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
