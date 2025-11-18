import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/objects/address_related/address.dart';
import 'package:gizmoglobe_client/widgets/order/invoice_details_widget.dart';

class OrderDetailBody extends StatelessWidget {
  final SalesInvoice invoice;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const OrderDetailBody({
    super.key,
    required this.invoice,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVietnameseLocale = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).orders,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${invoice.salesInvoiceID ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (showCloseButton)
                IconButton(
                  onPressed: onClose ??
                      () {
                        Navigator.of(context).maybePop();
                      },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 24),
          OrderStatusChip(invoice: invoice),
          const SizedBox(height: 24),
          OrderDetailSectionTitle(text: S.of(context).orderSummary),
          const SizedBox(height: 12),
          ...invoice.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InvoiceDetailsWidget(detail: detail),
            ),
          ),
          const SizedBox(height: 8),
          OrderDetailInfoRow(
            label: S.of(context).total,
            value: Helper.toCurrencyFormat(invoice.totalPrice),
            emphasis: true,
          ),
          const SizedBox(height: 24),
          OrderDetailSectionTitle(text: S.of(context).shippingAddress),
          const SizedBox(height: 12),
          OrderDetailShippingAddress(address: invoice.address),
          const SizedBox(height: 24),
          OrderDetailSectionTitle(text: S.of(context).paymentMethod),
          const SizedBox(height: 12),
          OrderDetailInfoRow(
            label: S.of(context).paymentMethod,
            value: invoice.paymentMethod
                .getLocalizedDescription(isVietnameseLocale),
          ),
          OrderDetailInfoRow(
            label: S.of(context).paymentStatus,
            value: invoice.paymentStatus
                .getLocalizedDescription(isVietnameseLocale),
          ),
          OrderDetailInfoRow(
            label: S.of(context).orderStatus,
            value:
                invoice.salesStatus.getLocalizedDescription(isVietnameseLocale),
          ),
        ],
      ),
    );
  }
}

class OrderDetailSectionTitle extends StatelessWidget {
  final String text;

  const OrderDetailSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class OrderDetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const OrderDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: emphasis
                ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class OrderDetailShippingAddress extends StatelessWidget {
  final Address? address;

  const OrderDetailShippingAddress({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    if (address == null) {
      return Text(
        S.of(context).noAddressFound,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address!.firstLine(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          address!.secondLine(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class OrderStatusChip extends StatelessWidget {
  final SalesInvoice invoice;

  const OrderStatusChip({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVietnameseLocale = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');
    final statusLabel =
        invoice.salesStatus.getLocalizedDescription(isVietnameseLocale);

    Color statusColor;
    switch (invoice.salesStatus) {
      case SalesStatus.pending:
        statusColor = colorScheme.tertiary;
        break;
      case SalesStatus.preparing:
        statusColor = colorScheme.secondary;
        break;
      case SalesStatus.shipping:
      case SalesStatus.shipped:
        statusColor = colorScheme.primary;
        break;
      case SalesStatus.completed:
        statusColor = colorScheme.secondaryContainer;
        break;
      default:
        statusColor = colorScheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
