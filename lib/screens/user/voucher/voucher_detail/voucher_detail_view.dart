import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/converter.dart';
import 'package:gizmoglobe_client/objects/voucher_related/limited_interface.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:intl/intl.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../generated/l10n.dart';
import '../../../../objects/voucher_related/end_time_interface.dart';
import '../../../../objects/voucher_related/percentage_interface.dart';
import '../../../../objects/voucher_related/voucher.dart';

class VoucherDetailScreen extends StatefulWidget {
  final Voucher voucher;
  const VoucherDetailScreen({super.key, required this.voucher});

  static Widget newInstance(Voucher voucher) => BlocProvider(
        create: (context) => VoucherDetailCubit(voucher),
        child: VoucherDetailScreen(voucher: voucher),
      );

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreen();
}

class _VoucherDetailScreen extends State<VoucherDetailScreen> {
  VoucherDetailCubit get cubit => context.read<VoucherDetailCubit>();

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BlocBuilder<VoucherDetailCubit, VoucherDetailState>(
          builder: (context, state) => GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () => {
              if (widget.voucher != state.voucher)
                {Navigator.pop(context, ProcessState.success)}
              else
                {Navigator.pop(context, state.processState)}
            },
            fillColor: Colors.transparent,
          ),
        ),
        title: Text(
          voucher.voucherName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(context, S.of(context).voucher,
                            voucher.voucherName),
                        const SizedBox(height: 12),
                        _buildTextField(
                            context,
                            S.of(context).startTime,
                            DateFormat('dd/MM/yyyy hh:mm:ss')
                                .format(voucher.startTime)),
                        const SizedBox(height: 12),
                        _buildTextField(context, S.of(context).minimumPurchase,
                            '\$${Converter.formatDouble(voucher.minimumPurchase)}'),
                        const SizedBox(height: 12),
                        if (voucher.isLimited)
                          _buildTextField(context, S.of(context).usage,
                              '${(voucher as LimitedInterface).usageLeft} / ${(voucher as LimitedInterface).maximumUsage}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          context,
                          S.of(context).discount,
                          voucher.isPercentage
                              ? '${Converter.formatDouble(voucher.discountValue)}% maximum \$${Converter.formatDouble((voucher as PercentageInterface).maximumDiscountValue)}'
                              : '\$${Converter.formatDouble(voucher.discountValue)}',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          context,
                          S.of(context).endTime,
                          voucher.hasEndTime
                              ? DateFormat('dd/MM/yyyy hh:mm:ss')
                                  .format((voucher as EndTimeInterface).endTime)
                              : 'No end time',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(context, 'Max. usage per person',
                            '${voucher.maxUsagePerPerson}'),
                        if (voucher.description != null) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                              context, 'Description', voucher.description!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: 4),
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
