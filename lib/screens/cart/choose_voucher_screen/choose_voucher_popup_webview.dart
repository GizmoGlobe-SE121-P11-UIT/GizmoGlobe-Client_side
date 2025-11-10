import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';

import '../../../enums/processing/process_state_enum.dart';
import '../../../functions/helper.dart';
import '../../user/voucher/voucher_detail/voucher_detail_webview.dart';
import 'choose_voucher_screen_cubit.dart';
import 'choose_voucher_screen_state.dart';

// Web-only helper to show the Choose Voucher screen as a modal dialog and return the selected Voucher
Future<Voucher?> showChooseVoucherModal(
  BuildContext context, {
  required double totalAmount,
  Voucher? currentVoucher,
}) {
  assert(kIsWeb, 'showChooseVoucherModal is intended for web usage');
  return showDialog<Voucher>(
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
                child: _ChooseVoucherPopupWebView.newInstance(
                  totalAmount: totalAmount,
                  currentVoucher: currentVoucher,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ChooseVoucherPopupWebView extends StatefulWidget {
  final double totalAmount;
  final Voucher? currentVoucher;

  const _ChooseVoucherPopupWebView({
    required this.totalAmount,
    this.currentVoucher,
  });

  static Widget newInstance({
    required double totalAmount,
    Voucher? currentVoucher,
  }) =>
      BlocProvider(
        create: (context) =>
            ChooseVoucherScreenCubit()..initialize(totalAmount),
        child: _ChooseVoucherPopupWebView(
          totalAmount: totalAmount,
          currentVoucher: currentVoucher,
        ),
      );

  @override
  State<_ChooseVoucherPopupWebView> createState() =>
      _ChooseVoucherPopupWebViewState();
}

class _ChooseVoucherPopupWebViewState
    extends State<_ChooseVoucherPopupWebView> {
  ChooseVoucherScreenCubit get cubit =>
      context.read<ChooseVoucherScreenCubit>();

  // Track temporarily selected voucher (before clicking the checkmark)
  Voucher? _temporarySelectedVoucher;

  @override
  void initState() {
    super.initState();
    // Initialize with current voucher if any
    _temporarySelectedVoucher = widget.currentVoucher;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          GradientText(text: S.of(context).chooseVoucher, fontSize: 24),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.pop(context, _temporarySelectedVoucher);
            },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChooseVoucherScreenCubit, ChooseVoucherScreenState>(
      builder: (context, state) {
        if (state.processState == ProcessState.loading) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 400,
                ),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ],
          );
        }

        if (state.availableVouchers.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 200,
                  maxHeight: 400,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60.0),
                  child: Text(
                    S.of(context).noVouchersAvailable,
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
            _buildHeader(context),
            // Content - Size to content, scroll when needed
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: state.availableVouchers.map((voucher) {
                  // Check against temporary selection instead of current voucher
                  final isSelected =
                      _temporarySelectedVoucher?.voucherID == voucher.voucherID;
                  final discount =
                      cubit.calculateDiscount(voucher, widget.totalAmount);

                  return GestureDetector(
                    onTap: () {
                      // Update temporary selection instead of closing dialog
                      setState(() {
                        // Toggle selection: if already selected, deselect; otherwise select
                        if (_temporarySelectedVoucher?.voucherID ==
                            voucher.voucherID) {
                          _temporarySelectedVoucher = null;
                        } else {
                          _temporarySelectedVoucher = voucher;
                        }
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucher.voucherName,
                                  style: AppTextStyle.boldText,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${S.of(context).minimumPurchaseAmount}: ${Helper.toCurrencyFormat(voucher.minimumPurchase)}",
                                  style: AppTextStyle.regularText.copyWith(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "- ${Helper.toCurrencyFormat(discount)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Always use modal on web since this popup is web-only
                              // Using modal prevents layout issues with nested routes
                              showVoucherDetailModal(context, voucher);
                            },
                            child: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
