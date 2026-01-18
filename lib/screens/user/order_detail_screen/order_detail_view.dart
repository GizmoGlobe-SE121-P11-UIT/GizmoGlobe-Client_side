import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_state.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/widgets/order_detail_sections.dart';

class OrderDetailView extends StatelessWidget {
  final SalesInvoice salesInvoice;

  const OrderDetailView({super.key, required this.salesInvoice});

  static Widget newInstance({required SalesInvoice salesInvoice}) =>
      BlocProvider(
        create: (context) => OrderDetailCubit()..loadOrderDetail(salesInvoice),
        child: OrderDetailView(salesInvoice: salesInvoice),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).orders),
        actions: [
          BlocBuilder<OrderDetailCubit, OrderDetailState>(
            builder: (context, state) {
              final invoice = state.salesInvoice;
              if (state.processState != ProcessState.success ||
                  invoice == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: S.of(context).downloadInvoice,
                icon: const Icon(Icons.download),
                onPressed: () => context
                    .read<OrderDetailCubit>()
                    .downloadInvoicePdf(context, invoice),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        builder: (context, state) {
          if (state.processState == ProcessState.loading ||
              state.salesInvoice == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.processState == ProcessState.failure) {
            return Center(
              child: Text(
                state.errorMessage ?? S.of(context).statusUnknown,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final invoice = state.salesInvoice!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OrderDetailBody(
              invoice: invoice,
              showCloseButton: false,
              onCancel: () =>
                  context.read<OrderDetailCubit>().cancelInvoice(context),
            ),
          );
        },
      ),
    );
  }
}
