import 'package:flutter/material.dart';
import '../../objects/voucher_related/voucher.dart';

class VoucherWidget extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onPressed;

  const VoucherWidget({
    super.key,
    required this.voucher,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: voucher.detailsWidget(context)
        ),
      ),
    );
  }
}