import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../../data/database/database.dart';
import '../../../objects/address_related/address.dart';
import '../../../widgets/general/gradient_checkbox.dart';
import 'add_address_screen_cubit.dart';
import '../../../widgets/general/address_picker.dart';

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
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Add Address', style: TextStyle(fontSize: 20)),
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
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  onAddressChanged: (province, district, ward) {
                    cubit.updateAddress(
                      province: province,
                      district: district,
                      ward: ward,
                    );
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
      ),
    );
  }
}