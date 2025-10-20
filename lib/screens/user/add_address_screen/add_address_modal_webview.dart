import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/widgets/general/address_picker.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/objects/address_related/address.dart';
import 'package:gizmoglobe_client/services/modal_overlay_service.dart';

import 'add_address_screen_cubit.dart';

/// Helper to open Add Address as a modal dialog with its own cubit
Future<Address?> showAddAddressModal(BuildContext context) {
  ModalOverlayService.setOpen(true);
  return showDialog<Address>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AddAddressWebModal.newInstance(),
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}

/// Helper to open Add Address modal reusing an existing cubit instance
Future<Address?> showAddAddressModalWithCubit(
  BuildContext context,
  AddAddressScreenCubit cubit,
) {
  ModalOverlayService.setOpen(true);
  return showDialog<Address>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AddAddressWebModal.withCubit(cubit),
  ).whenComplete(() => ModalOverlayService.setOpen(false));
}

class AddAddressWebModal extends StatefulWidget {
  const AddAddressWebModal({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => AddAddressScreenCubit(),
        child: const AddAddressWebModal(),
      );

  static Widget withCubit(AddAddressScreenCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const AddAddressWebModal(),
      );

  @override
  State<AddAddressWebModal> createState() => _AddAddressWebModalState();
}

class _AddAddressWebModalState extends State<AddAddressWebModal> {
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth <= 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth - 32 : 560,
          maxHeight: screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GradientText(text: S.of(context).addAddress, fontSize: 20),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, S.of(context).receiverName),
                      const SizedBox(height: 4),
                      _buildTextField(
                        context,
                        controller: _receiverNameController,
                        hintText: S.of(context).receiverName,
                        onChanged: (value) =>
                            cubit.updateAddress(receiverName: value),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(context, S.of(context).receiverPhone),
                      const SizedBox(height: 4),
                      _buildTextField(
                        context,
                        controller: _receiverPhoneController,
                        hintText: S.of(context).receiverPhone,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) =>
                            cubit.updateAddress(receiverPhone: value),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(context, S.of(context).address),
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
                      _buildLabel(context, S.of(context).streetAddress),
                      const SizedBox(height: 4),
                      _buildTextField(
                        context,
                        controller: _streetController,
                        hintText: S.of(context).streetAddress,
                        onChanged: (value) =>
                            cubit.updateAddress(street: value),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\s,\-\./]'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).save,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    return FieldWithIcon(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      fillColor: theme.colorScheme.surface,
      textColor: theme.colorScheme.onSurface,
      hintTextColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }

  void _handleSave() {
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
  }
}
