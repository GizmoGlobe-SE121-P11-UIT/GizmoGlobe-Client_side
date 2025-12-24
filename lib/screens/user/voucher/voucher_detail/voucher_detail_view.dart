import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/functions/converter.dart';
import 'package:gizmoglobe_client/objects/voucher_related/limited_interface.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_state.dart';
import 'package:intl/intl.dart';
import '../../../../functions/helper.dart';
import 'voucher_detail_webview.dart';

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

    // For web, show as a modal dialog and pop this route afterwards
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showVoucherDetailModal(context, voucher);
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    // For mobile, single-column plain text layout
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BlocBuilder<VoucherDetailCubit, VoucherDetailState>(
          builder: (context, state) => IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => {
              if (widget.voucher != state.voucher)
                {Navigator.pop(context, ProcessState.success)}
              else
                {Navigator.pop(context, state.processState)}
            },
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
              _plainField(context, S.of(context).voucher, voucher.voucherName),
              const SizedBox(height: 12),
              _plainField(
                context,
                S.of(context).startTime,
                DateFormat('dd/MM/yyyy hh:mm:ss').format(voucher.startTime),
              ),
              const SizedBox(height: 12),
              _plainField(
                context,
                S.of(context).minimumPurchase,
                Helper.toCurrencyFormat(voucher.minimumPurchase),
              ),
              const SizedBox(height: 12),
              if (voucher.isLimited)
                _plainField(
                  context,
                  S.of(context).usage,
                  '${(voucher as LimitedInterface).usageLeft} / ${(voucher as LimitedInterface).maximumUsage}',
                ),
              const SizedBox(height: 12),
              _plainField(
                context,
                S.of(context).discount,
                voucher.isPercentage
                    ? '${voucher.discountValue}% maximum ${Helper.toCurrencyFormat((voucher as PercentageInterface).maximumDiscountValue)}'
                    : Helper.toCurrencyFormat(voucher.discountValue),
              ),
              const SizedBox(height: 12),
              _plainField(
                context,
                S.of(context).endTime,
                voucher.hasEndTime
                    ? DateFormat('dd/MM/yyyy hh:mm:ss')
                    .format((voucher as EndTimeInterface).endTime)
                    : S.of(context).noEndTime,
              ),
              const SizedBox(height: 12),
              _plainField(
                context,
                S.of(context).maxUsagePerPerson,
                '${voucher.maxUsagePerPerson}',
              ),
              if (voucher.getDescription(context) != null) ...[
                const SizedBox(height: 12),
                _plainField(
                  context,
                  S.of(context).description,
                  voucher.getDescription(context)!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _plainField(BuildContext context, String label, String value) {
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
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
