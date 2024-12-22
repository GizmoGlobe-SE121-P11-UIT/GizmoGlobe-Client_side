import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../objects/address_related/address.dart';
import 'add_address_screen_cubit.dart';
import 'address_picker.dart';

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
  bool _isDefault = false;

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
                    receiverName: cubit.state.receiverName,
                    receiverPhone: cubit.state.receiverPhone,
                    province: cubit.state.province,
                    district: cubit.state.district,
                    ward: cubit.state.ward,
                    street: cubit.state.street,
                    isDefault: cubit.state.isDefault,
                  ),
                );
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _receiverNameController,
                decoration: const InputDecoration(labelText: 'Receiver Name'),
                onChanged: (value) {
                  cubit.updateAddress(receiverName: value);
                },
              ),
              TextField(
                controller: _receiverPhoneController,
                decoration: const InputDecoration(labelText: 'Receiver Phone'),
                onChanged: (value) {
                  cubit.updateAddress(receiverPhone: value);
                },
              ),
              AddressPicker(
                onAddressChanged: (province, district, ward) {
                  cubit.updateAddress(
                    province: province,
                    district: district,
                    ward: ward,
                  );
                },
              ),
              TextField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street'),
                onChanged: (value) {
                  cubit.updateAddress(street: value);
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value ?? false;
                      });
                      cubit.updateAddress(isDefault: _isDefault);
                    },
                  ),
                  const Text('Set as default address'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}