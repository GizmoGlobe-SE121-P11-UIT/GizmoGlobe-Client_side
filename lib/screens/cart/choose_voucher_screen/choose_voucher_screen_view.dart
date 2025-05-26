// lib/screens/cart/choose_voucher_screen/choose_voucher_screen_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/voucher_related/voucher.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:intl/intl.dart';
import '../../user/voucher/voucher_detail/voucher_detail_view.dart';
import 'choose_voucher_screen_cubit.dart';
import 'choose_voucher_screen_state.dart';

class ChooseVoucherScreen extends StatefulWidget {
  final double totalAmount;
  final Voucher? currentVoucher;

  const ChooseVoucherScreen({
    super.key,
    required this.totalAmount,
    this.currentVoucher,
  });

  static Widget newInstance({
    required double totalAmount,
    Voucher? currentVoucher,
  }) =>
      BlocProvider(
        create: (context) => ChooseVoucherScreenCubit(),
        child: ChooseVoucherScreen(
          totalAmount: totalAmount,
          currentVoucher: currentVoucher,
        ),
      );

  @override
  State<ChooseVoucherScreen> createState() => _ChooseVoucherScreenState();
}

class _ChooseVoucherScreenState extends State<ChooseVoucherScreen> {
  ChooseVoucherScreenCubit get cubit => context.read<ChooseVoucherScreenCubit>();

  @override
  void initState() {
    super.initState();
    cubit.initialize(widget.totalAmount);
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
        title: GradientText(text: 'Choose Voucher'),
      ),
      body: BlocBuilder<ChooseVoucherScreenCubit, ChooseVoucherScreenState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.availableVouchers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0),
                child: Text(
                  "No vouchers available",
                  style: AppTextStyle.regularText,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.availableVouchers.length,
            itemBuilder: (context, index) {
              final voucher = state.availableVouchers[index];
              final isSelected = widget.currentVoucher?.voucherID == voucher.voucherID;
              final discount = cubit.calculateDiscount(voucher, widget.totalAmount);

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, voucher);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.primary)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Min. purchase: \$${voucher.minimumPurchase.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "- \$${discount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoucherDetailScreen.newInstance(voucher),
                            ),
                          );
                        },
                        child: Text(
                          voucher.voucherName,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}