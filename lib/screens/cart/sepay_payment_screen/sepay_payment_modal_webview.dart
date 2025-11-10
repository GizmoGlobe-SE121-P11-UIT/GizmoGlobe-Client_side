import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'sepay_payment_screen_cubit.dart';
import 'sepay_payment_screen_state.dart';

/// Web-only helper to show SePay payment as a modal dialog and return success boolean
Future<bool?> showSePayPaymentModal(
  BuildContext context, {
  required String orderId,
  required double amount,
  String? customerName,
  String? description,
}) {
  assert(kIsWeb, 'showSePayPaymentModal is intended for web usage');
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final screenWidth = MediaQuery.of(ctx).size.width;
      final screenHeight = MediaQuery.of(ctx).size.height;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 640 ? 560 : screenWidth - 32,
            maxHeight: screenHeight * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(
                    alpha: theme.brightness == Brightness.light ? 0.08 : 0.24),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _SePayPaymentModal.newInstance(
              orderId: orderId,
              amount: amount,
              customerName: customerName,
              description: description,
            ),
          ),
        ),
      );
    },
  );
}

class _SePayPaymentModal extends StatefulWidget {
  final String orderId;
  final double amount;
  final String? customerName;
  final String? description;

  const _SePayPaymentModal({
    required this.orderId,
    required this.amount,
    this.customerName,
    this.description,
  });

  static Widget newInstance({
    required String orderId,
    required double amount,
    String? customerName,
    String? description,
  }) =>
      BlocProvider(
        create: (context) => SePayPaymentScreenCubit()
          ..initializePayment(
            orderId: orderId,
            amount: amount,
            customerName: customerName,
            description: description,
          ),
        child: _SePayPaymentModal(
          orderId: orderId,
          amount: amount,
          customerName: customerName,
          description: description,
        ),
      );

  @override
  State<_SePayPaymentModal> createState() => _SePayPaymentModalState();
}

class _SePayPaymentModalState extends State<_SePayPaymentModal> {
  SePayPaymentScreenCubit get cubit => context.read<SePayPaymentScreenCubit>();

  @override
  void dispose() {
    // Ensure timers/listeners are stopped before Bloc is disposed
    try {
      cubit.cancelPolling();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double headerHeight = 56;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBodyHeight = (constraints.maxHeight - headerHeight)
            .clamp(120.0, constraints.maxHeight);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child:
                  BlocBuilder<SePayPaymentScreenCubit, SePayPaymentScreenState>(
                buildWhen: (previous, current) =>
                    previous.isRestoringCart != current.isRestoringCart,
                builder: (context, modalState) {
                  return Row(
                    children: [
                      Text(
                        S.of(context).sepay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: modalState.isRestoringCart
                            ? null
                            : () async {
                                final success = await cubit.handleDismissal();
                                if (!context.mounted) return;
                                if (!success &&
                                    cubit.state.dismissError != null) {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => InformationDialog(
                                      title: S.of(ctx).paymentStatus,
                                      content: cubit.state.dismissError!,
                                      dialogName: DialogName.failure,
                                      buttonText: S.of(ctx).ok,
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  );
                                  cubit.clearDismissError();
                                }
                                if (context.mounted) {
                                  Navigator.pop(context, false);
                                }
                              },
                        icon: const Icon(Icons.close),
                        tooltip: S.of(context).sepayClose,
                      ),
                    ],
                  );
                },
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxBodyHeight,
              ),
              child: BlocConsumer<SePayPaymentScreenCubit,
                  SePayPaymentScreenState>(
                listener: (context, state) {
                  if (!context.mounted) return;
                  if (state.processState == ProcessState.success) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => InformationDialog(
                        title: S.of(context).paymentStatus,
                        content: S.of(context).sepayPaymentSuccessMessage,
                        dialogName: DialogName.success,
                        buttonText: S.of(context).ok,
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          navigator.pop(); // close dialog
                          try {
                            cubit.cancelPolling();
                          } catch (_) {}
                          navigator.pop(true); // close modal with success
                        },
                      ),
                    );
                  } else if (state.processState == ProcessState.failure) {
                    showDialog(
                      context: context,
                      builder: (context) => InformationDialog(
                        title: S.of(context).paymentStatus,
                        content: state.message.isNotEmpty
                            ? state.message
                            : S.of(context).sepayPaymentInitFailed,
                        dialogName: DialogName.failure,
                        buttonText: S.of(context).sepayClose,
                        onPressed: () => Navigator.pop(context),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.processState == ProcessState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.virtualAccount == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              state.message.isNotEmpty
                                  ? state.message
                                  : S.of(context).sepayPaymentInitFailed,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(S.of(context).sepayClose),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final va = state.virtualAccount!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isRestoringCart)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  S.of(context).sepayRestoringCart,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (state.dismissError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.dismissError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // QR
                        if (va.qrCode != null && va.qrCode!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.network(
                              va.qrCode!,
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.qr_code, size: 120);
                              },
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Details (compact)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              _detailRow(
                                  context,
                                  S.of(context).sepayAmountLabel,
                                  Helper.toCurrencyVND(va.amount)),
                              const SizedBox(height: 8),
                              _detailRow(
                                  context,
                                  S.of(context).sepayBankAccountLabel,
                                  va.accountNumber),
                              const SizedBox(height: 8),
                              _detailRow(context, S.of(context).sepayBankLabel,
                                  va.bankName),
                              if (va.orderId.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _detailRow(
                                    context,
                                    S.of(context).sepayOrderIdLabel,
                                    va.orderId),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (state.isPolling)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    S.of(context).sepayWaitingForPayment,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
