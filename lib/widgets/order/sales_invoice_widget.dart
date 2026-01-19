// dart
import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/widgets/order/invoice_details_widget.dart';
import '../../enums/invoice_related/sales_status.dart';
import '../../functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import '../../objects/invoice_related/rating.dart';

class SalesInvoiceWidget extends StatelessWidget {
  final SalesInvoice salesInvoice;
  final VoidCallback onPressed;
  final VoidCallback? onTap;
  final void Function(String productID)? onRate;
  final List<Rating>? userRatings; // current user's ratings

  const SalesInvoiceWidget({
    super.key,
    required this.salesInvoice,
    required this.onPressed,
    this.onTap,
    this.onRate,
    this.userRatings,
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
                children: salesInvoice.details.map((detail) {
                  final productId = detail.product.productID ?? '';
                  final invoiceId = salesInvoice.salesInvoiceID ?? '';
                  final alreadyRated = (userRatings ?? []).any((r) {
                    if (r.productID != productId) return false;
                    // Only block rating for the same invoice.
                    // Backward-compat: old ratings without invoiceId should NOT block re-rating in a new invoice.
                    return r.invoiceId != null &&
                        r.invoiceId!.isNotEmpty &&
                        r.invoiceId == invoiceId;
                  });
                  // Only show rate button when order is received or completed
                  // Don't show when still waiting for delivery (shipped)
                  final canRate = (salesInvoice.salesStatus ==
                              SalesStatus.received ||
                          salesInvoice.salesStatus == SalesStatus.completed) &&
                      onRate != null &&
                      productId.isNotEmpty &&
                      !alreadyRated;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InvoiceDetailsWidget(detail: detail),
                        const SizedBox(height: 8),
                        if (canRate)
                          Row(
                            children: [
                              const Spacer(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: FilledButton(
                                        onPressed: () => onRate!(productId),
                                        child: Text(S.of(context).rateProduct),
                                      ),
                                    ),
                                    Text(
                                      S.of(context).toGetPoints(200),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }).toList(),
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
                                        .withValues(alpha: 0.8),
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
        final int points = salesInvoice.totalPrice.round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusChip(
              text: localizedStatus,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: FilledButton(
                    onPressed: onPressed,
                    child: Text(S.of(context).received),
                  ),
                ),
                Text(
                  S.of(context).toGetPoints(points),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ],
        );
      case SalesStatus.received:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.secondary,
        );
      case SalesStatus.completed:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.secondary,
        );
      case SalesStatus.cancelled:
        return _StatusChip(
          text: localizedStatus,
          color: colorScheme.secondary,
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
