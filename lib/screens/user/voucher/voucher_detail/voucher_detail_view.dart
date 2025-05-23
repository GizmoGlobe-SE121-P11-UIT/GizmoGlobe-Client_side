import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/converter.dart';
import 'package:gizmoglobe_client/objects/voucher_related/limited_interface.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:intl/intl.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../objects/voucher_related/end_time_interface.dart';
import '../../../../objects/voucher_related/percentage_interface.dart';
import '../../../../objects/voucher_related/voucher.dart';
import '../../../../widgets/general/gradient_text.dart';

class VoucherDetailScreen extends StatefulWidget {
  final Voucher voucher;
  const VoucherDetailScreen({super.key, required this.voucher});

  static Widget newInstance(Voucher voucher) =>
      BlocProvider(
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BlocBuilder<VoucherDetailCubit, VoucherDetailState>(
          builder: (context, state) =>
              GradientIconButton(
                icon: Icons.chevron_left,
                onPressed: () =>
                {
                  if (widget.voucher != state.voucher) {
                    Navigator.pop(context, ProcessState.success)
                  } else
                    {
                      Navigator.pop(context, state.processState)
                    }
                },
                fillColor: Colors.transparent,
              ),
        ),
        title: GradientText(
          text: widget.voucher.voucherName,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    title: 'Voucher',
                    value: widget.voucher.voucherName,
                  ),

                  _buildInfoRow(
                    title: 'Discount',
                    value: widget.voucher.isPercentage
                        ? '${Converter.formatDouble(widget.voucher.discountValue)}% maximum \$${Converter.formatDouble((widget.voucher as PercentageInterface).maximumDiscountValue)}'
                        : '\$${Converter.formatDouble(widget.voucher.discountValue)}',
                  ),

                  _buildInfoRow(
                    title: 'Minimum purchase',
                    value: '\$${Converter.formatDouble(widget.voucher.minimumPurchase)}',
                  ),

                  if (widget.voucher.isLimited)
                    _buildInfoRow(
                      title: 'Usage',
                      value: '${(widget.voucher as LimitedInterface).usageLeft} / ${(widget.voucher as LimitedInterface).maximumUsage}',
                    ),

                  _buildInfoRow(
                    title: 'Maximum usage per person',
                    value: '${widget.voucher.maxUsagePerPerson}',
                  ),

                  _buildInfoRow(
                    title: 'Start time',
                    value: DateFormat('hh:mm:ss dd/MM/yyyy').format(widget.voucher.startTime),
                  ),

                  if (widget.voucher.hasEndTime)
                    _buildInfoRow(
                      title: 'End time',
                      value: DateFormat('hh:mm:ss dd/MM/yyyy').format((widget.voucher as EndTimeInterface).endTime),
                    )
                  else
                    _buildInfoRow(
                      title: 'End time',
                      value: 'No end time',
                    ),

                  _buildInfoRow(
                      title: 'Visibility',
                      value: widget.voucher.isVisible ? 'Visible' : 'Hidden'
                  ),

                  _buildInfoRow(
                      title: 'Status',
                      value: widget.voucher.isEnabled ? 'Enabled' : 'Disabled'
                  ),

                  if (widget.voucher.description != null)
                    _buildInfoRow(
                      title: 'Description',
                      value: widget.voucher.description!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}