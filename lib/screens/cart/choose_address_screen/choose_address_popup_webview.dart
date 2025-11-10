import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/widgets/general/invisible_gradient_button.dart';

import '../../../objects/address_related/address.dart';
import '../../user/add_address_screen/add_address_screen_view.dart';
import 'choose_address_screen_cubit.dart';
import 'choose_address_screen_state.dart';

// Web-only helper to show the Choose Address screen as a modal dialog and return the selected Address
Future<Address?> showChooseAddressModal(
  BuildContext context, {
  required Address currentAddress,
}) {
  assert(kIsWeb, 'showChooseAddressModal is intended for web usage');
  return showDialog<Address>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final screenWidth = MediaQuery.of(ctx).size.width;
      final screenHeight = MediaQuery.of(ctx).size.height;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 600 ? 560 : screenWidth - 32,
            maxHeight: screenHeight * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(
                      alpha: theme.brightness == Brightness.light ? 0.1 : 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: _ChooseAddressPopupWebView.newInstance(
                  address: currentAddress,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ChooseAddressPopupWebView extends StatefulWidget {
  final Address address;

  const _ChooseAddressPopupWebView({
    required this.address,
  });

  static Widget newInstance({
    required Address address,
  }) =>
      BlocProvider(
        create: (context) => ChooseAddressScreenCubit()..reloadList(),
        child: _ChooseAddressPopupWebView(address: address),
      );

  @override
  State<_ChooseAddressPopupWebView> createState() =>
      _ChooseAddressPopupWebViewState();
}

class _ChooseAddressPopupWebViewState
    extends State<_ChooseAddressPopupWebView> {
  ChooseAddressScreenCubit get cubit =>
      context.read<ChooseAddressScreenCubit>();
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.address;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChooseAddressScreenCubit, ChooseAddressScreenState>(
      builder: (context, state) {
        if (state.addressList.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    GradientText(text: S.of(context).address, fontSize: 24),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(
                          context, _selectedAddress ?? Address.nullAddress),
                      icon: Icon(
                        Icons.check,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.6),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Empty state
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Center(
                  child: Text(
                    S.of(context).noAddressFound,
                    style: AppTextStyle.regularText,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  GradientText(text: S.of(context).address, fontSize: 24),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(
                        context, _selectedAddress ?? Address.nullAddress),
                    icon: Icon(
                      Icons.check,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.6),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content - Size to content, scroll when needed
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...state.addressList.map((address) {
                    final isSelected =
                        _selectedAddress?.addressID == address.addressID;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAddress = address;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                    );
                  }),
                  Center(
                    child: InvisibleGradientButton(
                      text: S.of(context).addAddress,
                      prefixIcon: Icons.add,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AddAddressScreen.newInstance()),
                        );

                        if (result != null && result is Address) {
                          cubit.addAddress(result);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
