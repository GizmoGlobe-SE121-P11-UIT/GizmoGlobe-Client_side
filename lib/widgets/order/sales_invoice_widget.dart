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
                      'Total ${salesInvoice.getTotalItems()} items: \$${salesInvoice.totalPrice.toStringAsFixed(2)}', // 'Tổng ${salesInvoice.getTotalItems()} sản phẩm: \$${salesInvoice.totalPrice.toStringAsFixed(2)}'
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
              'Your order is being processed.', // 'Đơn hàng của bạn đang được xử lý.'
              style: AppTextStyle.bigText,
            ),
          ],
        );

      case SalesStatus.preparing:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order is being prepared.', // 'Đơn hàng của bạn đang được chuẩn bị.'
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipping:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order is on the way.', // 'Đơn hàng của bạn đang trên đường giao.'
              style: AppTextStyle.bigText,
            ),
          ],
        );
      case SalesStatus.shipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Your order has been delivered.', // 'Đơn hàng của bạn đã được giao.'
              style: AppTextStyle.bigText,
            ),
            const SizedBox(height: 4),
            const Text(
              'Please confirm the delivery.', // 'Vui lòng xác nhận đã nhận hàng.'
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
              child: Text('Received', style: AppTextStyle.buttonTextBold.copyWith(color: Colors.white)), // 'Đã nhận'
            ),
          ],
        );
      case SalesStatus.completed:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your order has been completed.', // 'Đơn hàng của bạn đã hoàn thành.'
              style: AppTextStyle.bigText,
            ),
            SizedBox(height: 4),
            Text(
              'Thank you for your purchase!', // 'Cảm ơn bạn đã mua hàng!'
              style: AppTextStyle.bigText,
            ),
          ],
        );
      default:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Status: Unknown', // 'Trạng thái: Không xác định'
              style: AppTextStyle.bigText,
            ),
            SizedBox(height: 8),
            Text(
              'Please contact support.', // 'Vui lòng liên hệ hỗ trợ.'
              style: AppTextStyle.bigText,
            ),
          ],
        );
    }
  }
}