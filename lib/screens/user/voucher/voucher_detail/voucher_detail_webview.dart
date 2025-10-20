import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/converter.dart';
import 'package:gizmoglobe_client/objects/voucher_related/limited_interface.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_cubit.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:intl/intl.dart';

import '../../../../generated/l10n.dart';
import '../../../../objects/voucher_related/end_time_interface.dart';
import '../../../../objects/voucher_related/percentage_interface.dart';
import '../../../../objects/voucher_related/voucher.dart';

Future<void> showVoucherDetailModal(BuildContext context, Voucher voucher) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => VoucherDetailWebModal.newInstance(voucher),
  );
}

class VoucherDetailWebModal extends StatefulWidget {
  final Voucher voucher;

  const VoucherDetailWebModal({super.key, required this.voucher});

  static Widget newInstance(Voucher voucher) => BlocProvider(
        create: (context) => VoucherDetailCubit(voucher),
        child: VoucherDetailWebModal(voucher: voucher),
      );

  static Widget withCubit(VoucherDetailCubit cubit, Voucher voucher) =>
      BlocProvider.value(
        value: cubit,
        child: VoucherDetailWebModal(voucher: voucher),
      );

  @override
  State<VoucherDetailWebModal> createState() => _VoucherDetailWebModalState();
}

class _VoucherDetailWebModalState extends State<VoucherDetailWebModal> {
  VoucherDetailCubit get cubit => context.read<VoucherDetailCubit>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth <= 768;

    final voucher = widget.voucher;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth - 32 : 800,
          maxHeight: screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.voucherName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(voucher),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Voucher voucher) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          // Wide screen layout - two columns
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                        context, S.of(context).voucher, voucher.voucherName),
                    const SizedBox(height: 16),
                    _buildTextField(
                        context,
                        S.of(context).startTime,
                        DateFormat('dd/MM/yyyy hh:mm:ss')
                            .format(voucher.startTime)),
                    const SizedBox(height: 16),
                    _buildTextField(context, S.of(context).minimumPurchase,
                        '\$${Converter.formatDouble(voucher.minimumPurchase)}'),
                    const SizedBox(height: 16),
                    if (voucher.isLimited)
                      _buildTextField(context, S.of(context).usage,
                          '${(voucher as LimitedInterface).usageLeft} / ${(voucher as LimitedInterface).maximumUsage}'),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      context,
                      S.of(context).discount,
                      voucher.isPercentage
                          ? '${Converter.formatDouble(voucher.discountValue)}% ${S.of(context).maximumDiscount} \$${Converter.formatDouble((voucher as PercentageInterface).maximumDiscountValue)}'
                          : '\$${Converter.formatDouble(voucher.discountValue)}',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      S.of(context).endTime,
                      voucher.hasEndTime
                          ? DateFormat('dd/MM/yyyy hh:mm:ss')
                              .format((voucher as EndTimeInterface).endTime)
                          : S.of(context).noEndTime,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, S.of(context).maxUsagePerPerson,
                        '${voucher.maxUsagePerPerson}'),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Narrow screen layout - single column
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                  context, S.of(context).voucher, voucher.voucherName),
              const SizedBox(height: 16),
              _buildTextField(context, S.of(context).startTime,
                  DateFormat('dd/MM/yyyy hh:mm:ss').format(voucher.startTime)),
              const SizedBox(height: 16),
              _buildTextField(context, S.of(context).minimumPurchase,
                  '\$${Converter.formatDouble(voucher.minimumPurchase)}'),
              const SizedBox(height: 16),
              if (voucher.isLimited)
                _buildTextField(context, S.of(context).usage,
                    '${(voucher as LimitedInterface).usageLeft} / ${(voucher as LimitedInterface).maximumUsage}'),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                S.of(context).discount,
                voucher.isPercentage
                    ? '${Converter.formatDouble(voucher.discountValue)}% ${S.of(context).maximumDiscount} \$${Converter.formatDouble((voucher as PercentageInterface).maximumDiscountValue)}'
                    : '\$${Converter.formatDouble(voucher.discountValue)}',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                S.of(context).endTime,
                voucher.hasEndTime
                    ? DateFormat('dd/MM/yyyy hh:mm:ss')
                        .format((voucher as EndTimeInterface).endTime)
                    : S.of(context).noEndTime,
              ),
              const SizedBox(height: 16),
              _buildTextField(context, S.of(context).maxUsagePerPerson,
                  '${voucher.maxUsagePerPerson}'),
            ],
          );
        }
      },
    );
  }

  Widget _buildTextField(BuildContext context, String label, String value) {
    final controller = TextEditingController(text: value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        FieldWithIcon(
          controller: controller,
          readOnly: true,
          hintText: value,
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }
}
