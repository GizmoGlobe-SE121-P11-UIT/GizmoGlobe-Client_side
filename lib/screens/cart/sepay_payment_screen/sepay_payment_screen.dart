import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/widgets/dialog/information_dialog.dart';
import '../../../enums/processing/dialog_name_enum.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'sepay_payment_screen_cubit.dart';
import 'sepay_payment_screen_state.dart';

class SePayPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String? customerName;
  final String? description;

  const SePayPaymentScreen({
    super.key,
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
        child: SePayPaymentScreen(
          orderId: orderId,
          amount: amount,
          customerName: customerName,
          description: description,
        ),
      );

  @override
  State<SePayPaymentScreen> createState() => _SePayPaymentScreenState();
}

class _SePayPaymentScreenState extends State<SePayPaymentScreen> {
  SePayPaymentScreenCubit get cubit => context.read<SePayPaymentScreenCubit>();

  @override
  void initState() {
    super.initState();
    // Polling is now handled by the cubit
    // It uses both Firestore listener (for webhooks) and polling (as fallback)
  }

  @override
  void dispose() {
    // Cubit will clean up listeners and timers in close()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BlocBuilder<SePayPaymentScreenCubit, SePayPaymentScreenState>(
          buildWhen: (previous, current) =>
              previous.isRestoringCart != current.isRestoringCart,
          builder: (context, modalState) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: modalState.isRestoringCart
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cancel Payment'),
                          content: const Text(
                              'Are you sure you want to cancel? Payment will not be processed.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext); // close confirm
                                final success = await cubit.handleDismissal();
                                if (!mounted) return;
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
                                if (mounted) {
                                  Navigator.pop(context, false);
                                }
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                    },
            );
          },
        ),
        title: Text(S.of(context).sepay),
      ),
      body: BlocConsumer<SePayPaymentScreenCubit, SePayPaymentScreenState>(
        listener: (context, state) {
          if (state.processState == ProcessState.success) {
            // Polling and listeners are managed by cubit, no need to cancel here
            // Show success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InformationDialog(
                title: S.of(context).paymentStatus,
                content: S.of(context).sepayPaymentSuccessMessage,
                dialogName: DialogName.success,
                buttonText: S.of(context).ok,
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(
                      context, true); // Return to checkout with success
                },
              ),
            );
          } else if (state.processState == ProcessState.failure) {
            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => InformationDialog(
                title: S.of(context).paymentStatus,
                content: state.message.isNotEmpty
                    ? state.message
                    : S.of(context).sepayPaymentInitFailed,
                dialogName: DialogName.failure,
                buttonText: S.of(context).sepayGoBack,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message.isNotEmpty
                        ? state.message
                        : S.of(context).sepayPaymentInitFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(S.of(context).sepayGoBack),
                  ),
                ],
              ),
            );
          }

          final va = state.virtualAccount!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (state.isRestoringCart)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          S.of(context).sepayRestoringCart,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.dismissError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.dismissError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Payment instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).sepayScanInstructionsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).sepayScanInstructionsSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code
                if (va.qrCode != null && va.qrCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.network(
                      va.qrCode!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 64);
                      },
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code, size: 250),
                  ),

                const SizedBox(height: 24),

                // Payment details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).sepayPaymentDetailsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context,
                        S.of(context).sepayAmountLabel,
                        Helper.toCurrencyVND(va.amount),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        S.of(context).sepayBankAccountLabel,
                        va.accountNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        S.of(context).sepayBankLabel,
                        va.bankName,
                      ),
                      if (va.orderId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          S.of(context).sepayOrderIdLabel,
                          va.orderId,
                        ),
                        const SizedBox(height: 12),
                        // Transfer content required for webhook auto-matching
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Nội dung',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Order ${va.orderId}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Copy',
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(
                                            text: 'Order ${va.orderId}'),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Đã sao chép nội dung chuyển khoản'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment status
                if (state.isPolling)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            S.of(context).sepayWaitingForPayment,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Manual payment instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).sepayManualInstructionsTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        // Emphasize that content must include "Order {orderId}" for webhook auto-match
                        '${S.of(context).sepayManualInstructions}\n\n'
                        'Lưu ý: Nội dung chuyển khoản phải có "Order ${va.orderId}" để hệ thống tự động xác nhận thanh toán.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
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
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
