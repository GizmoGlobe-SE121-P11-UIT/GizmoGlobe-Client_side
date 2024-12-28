import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/widgets/order/invoice_details_widget.dart';

import '../../enums/invoice_related/sales_status.dart';
import '../general/app_text_style.dart';

class SalesInvoiceWidget extends StatelessWidget {
  final SalesInvoice salesInvoice;
  final VoidCallback onPressed;

  const SalesInvoiceWidget({
    super.key,
    required this.salesInvoice,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: salesInvoice.details.map((detail) {
                  return InvoiceDetailsWidget(
                    detail: detail,
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total ${salesInvoice.getTotalItems()} items: \$${salesInvoice.totalPrice.toStringAsFixed(2)}',
                      style: AppTextStyle.regularText,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusWidget(salesInvoice, onPressed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(SalesInvoice salesInvoice, VoidCallback onPressed) {
    switch (salesInvoice.salesStatus) {
      case SalesStatus.pending:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order is being processed.',
              style: AppTextStyle.bigText,
            ),
          ],
        );

      case SalesStatus.preparing:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order is being prepared.',
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipping:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order is on the way.',
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Your order has been delivered.',
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 4),
            const Text(
              'Please confirm the delivery.',
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Received', style: AppTextStyle.buttonTextBold.copyWith(color: Colors.white)),
            ),
          ],
        );
      case SalesStatus.completed:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order has been completed.',
              style: AppTextStyle.bigText,
            ),
            SizedBox(height: 4),
            Text(
              'Thank you for your purchase!',
              style: AppTextStyle.bigText,
            ),
          ],
        );
      default:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Status: Unknown',
              style: AppTextStyle.bigText,
            ),
            SizedBox(height: 8),
            Text(
              'Please contact support.',
              style: AppTextStyle.bigText,
            ),
          ],
        );
    }
  }
}