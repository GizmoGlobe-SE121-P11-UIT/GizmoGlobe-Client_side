import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_state.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/widgets/order_detail_sections.dart';

class OrderDetailWebView extends StatelessWidget {
  final SalesInvoice salesInvoice;

  const OrderDetailWebView({super.key, required this.salesInvoice});

  static Future<void> show(
    BuildContext context, {
    required SalesInvoice salesInvoice,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        backgroundColor: Colors.transparent,
        child: OrderDetailWebView(salesInvoice: salesInvoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderDetailCubit()..loadOrderDetail(salesInvoice),
      child: const _OrderDetailContent(),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      builder: (context, state) {
        if (state.processState == ProcessState.loading ||
            state.salesInvoice == null) {
          return _buildContainer(
            context,
            child: const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state.processState == ProcessState.failure) {
          return _buildContainer(
            context,
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  state.errorMessage ?? S.of(context).statusUnknown,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final invoice = state.salesInvoice!;
        return _buildContainer(
          context,
          child: SizedBox(
            width: 760,
            child: OrderDetailBody(
              invoice: invoice,
              showCloseButton: true,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, {required Widget child}) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
