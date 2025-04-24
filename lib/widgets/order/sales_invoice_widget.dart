import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/widgets/order/invoice_details_widget.dart';
import '../../enums/invoice_related/sales_status.dart';
import '../general/app_text_style.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

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
                    _buildStatusWidget(context, salesInvoice, onPressed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(
      BuildContext context, SalesInvoice salesInvoice, VoidCallback onPressed) {
    switch (salesInvoice.salesStatus) {
      case SalesStatus.pending:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).orderProcessing,
              style: AppTextStyle.bigText,
            ),
          ],
        );

      case SalesStatus.preparing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).orderPreparing,
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipping:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).orderShipping,
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).orderDelivered,
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).pleaseConfirmDelivery,
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
              child: Text(S.of(context).received,
                  style: AppTextStyle.buttonTextBold
                      .copyWith(color: Colors.white)),
            ),
          ],
        );
      case SalesStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).orderCompleted,
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).thankYou,
              style: AppTextStyle.bigText,
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              S.of(context).statusUnknown,
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).pleaseContactSupport,
              style: AppTextStyle.bigText,
            ),
          ],
        );
    }
  }
}