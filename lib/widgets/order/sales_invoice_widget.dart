import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/widgets/order/invoice_details_widget.dart';
import '../../enums/invoice_related/sales_status.dart';
import '../../functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class SalesInvoiceWidget extends StatelessWidget {
  final SalesInvoice salesInvoice;
  final VoidCallback onPressed;
  final VoidCallback? onTap;

  const SalesInvoiceWidget({
    super.key,
    required this.salesInvoice,
    required this.onPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: salesInvoice.details
                    .map(
                      (detail) => InvoiceDetailsWidget(detail: detail),
                    )
                    .toList(),
              ),
              const Divider(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).totalItems(salesInvoice.getTotalItems(),
                              Helper.toCurrencyFormat(salesInvoice.totalPrice)),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${salesInvoice.salesInvoiceID ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildStatusWidget(context, salesInvoice, onPressed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(
      BuildContext context, SalesInvoice salesInvoice, VoidCallback onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVietnameseLocale = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');
    final localizedStatus =
        salesInvoice.salesStatus.getLocalizedDescription(isVietnameseLocale);

    switch (salesInvoice.salesStatus) {
      case SalesStatus.pending:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.tertiary,
        );

      case SalesStatus.preparing:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.secondary,
        );
      case SalesStatus.shipping:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.primary,
        );
      case SalesStatus.shipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusChip(
              text: localizedStatus,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).pleaseConfirmDelivery,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onPressed,
              child: Text(S.of(context).received),
            ),
          ],
        );
      case SalesStatus.completed:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.secondary,
        );
      default:
        return _StatusChip(
          text: S.of(context).statusUnknown,
          color: colorScheme.error,
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
