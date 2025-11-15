import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/widgets/general/invisible_gradient_button.dart';

import '../../../objects/address_related/address.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../user/add_address_screen/add_address_screen_view.dart';
import 'choose_address_screen_cubit.dart';
import 'choose_address_screen_state.dart';

class ChooseAddressScreen extends StatefulWidget {
  final Address address;

  const ChooseAddressScreen({super.key, required this.address});

  static Widget newInstance({required Address address}) => BlocProvider(
        create: (context) => ChooseAddressScreenCubit(),
        child: ChooseAddressScreen(address: address),
      );

  @override
  State<ChooseAddressScreen> createState() => _ChooseAddressScreen();
}

class _ChooseAddressScreen extends State<ChooseAddressScreen> {
  ChooseAddressScreenCubit get cubit =>
      context.read<ChooseAddressScreenCubit>();
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    cubit.reloadList();
    _selectedAddress = widget.address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GradientIconButton(
          icon: Icons.chevron_left,
          onPressed: () {
            Navigator.pop(context);
          },
          fillColor: Colors.transparent,
        ),
        title: GradientText(text: S.of(context).address),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _selectedAddress ?? Address.nullAddress);
            },
            icon: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ),
            tooltip: S.of(context).confirm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              BlocBuilder<ChooseAddressScreenCubit, ChooseAddressScreenState>(
                builder: (context, state) {
                  return state.addressList.isEmpty
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Text(
                            S.of(context).noAddressFound,
                            style: AppTextStyle.regularText,
                          ),
                        ))
                      : Column(
                          children: state.addressList.map((address) {
                            final isSelected =
                                _selectedAddress?.addressID == address.addressID;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAddress = address;
                                });
                              },
                              child: ListTile(
                                title: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        address.firstLine(),
                                        style: AppTextStyle.boldText,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.secondLine(),
                                        style: AppTextStyle.regularText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                },
              ),
              InvisibleGradientButton(
                text: S.of(context).addAddress,
                prefixIcon: Icons.add,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddAddressScreen.newInstance()),
                  );

                  if (result != null && result is Address) {
                    cubit.addAddress(result);
                    setState(() {
                      _selectedAddress = result;
                    });
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
