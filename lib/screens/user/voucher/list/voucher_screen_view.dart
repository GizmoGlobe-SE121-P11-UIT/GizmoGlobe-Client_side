import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_view.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/widgets/voucher/redeemable_voucher_widget.dart';
import 'voucher_screen_webview.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../objects/voucher_related/voucher.dart';
import '../../../../widgets/dialog/information_dialog.dart';
import '../../../../widgets/general/app_text_style.dart';
import '../../../../widgets/voucher/voucher_widget.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => VoucherScreenCubit(),
        child: const VoucherScreen(),
      );

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (_) => VoucherScreen.newInstance());
  }

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen>
    with SingleTickerProviderStateMixin {
  VoucherScreenCubit get cubit => context.read<VoucherScreenCubit>();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    cubit.toLoading();
    Future.microtask(() async {
      await cubit.initialize();
    });
    // Now three tabs: ongoing, upcoming, redeem
    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // For web, use the webview component directly
    if (kIsWeb) {
      return VoucherScreenWebView.withCubit(cubit);
    }

    // For mobile, use the three-tab layout: ongoing, upcoming, redeem
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: GradientText(text: S.of(context).voucher),
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.fill,
            indicator: const BoxDecoration(),
            tabs: [
              Tab(text: S.of(context).ongoing),
              Tab(text: S.of(context).upcoming),
              Tab(text: S.of(context).redeem),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<VoucherScreenCubit, VoucherScreenState>(
            listener: (context, state) {
              if (state.processState == ProcessState.success) {
                if (state.dialogMessage.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => InformationDialog(
                      title: state.dialogName.description,
                      content: state.dialogMessage,
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    VoucherScreen.newInstance()));
                      },
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state.processState == ProcessState.loading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.processState == ProcessState.failure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context).error,
                        style: AppTextStyle.regularText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.dialogMessage,
                        style: AppTextStyle.regularText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          cubit.toLoading();
                          Future.microtask(() async {
                            await cubit.initialize();
                          });
                        },
                        child: Text(S.of(context).retry),
                      ),
                    ],
                  ),
                );
              }

              // When loaded, show TabBarView with three children
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Ongoing
                    state.ongoingList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noVouchersAvailable,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.ongoingList.length,
                            itemBuilder: (context, index) {
                              final voucher = state.ongoingList[index];
                              return VoucherWidget(
                                voucher: voucher,
                                onPressed: () =>
                                    _onVoucherTap(context, voucher),
                              );
                            },
                          ),

                    // Upcoming
                    state.upcomingList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noVouchersAvailable,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.upcomingList.length,
                            itemBuilder: (context, index) {
                              final voucher = state.upcomingList[index];
                              return VoucherWidget(
                                voucher: voucher,
                                onPressed: () =>
                                    _onVoucherTap(context, voucher),
                              );
                            },
                          ),

                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    S.of(context).loyalPoints,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.points}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.auto_awesome,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // redeem list or empty message
                        Expanded(
                          child: state.redeemableList.isEmpty
                              ? Center(
                                  child: Text(
                                    S.of(context).noVoucherToRedeem,
                                    style: AppTextStyle.regularText,
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.redeemableList.length,
                                  itemBuilder: (context, index) {
                                    final v = state.redeemableList[index];
                                    return RedeemableVoucherWidget(
                                      voucher: v,
                                      onPressed: () =>
                                          _onVoucherTap(context, v),
                                      onRedeem: () => cubit.redeemVoucher(v),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onVoucherTap(BuildContext context, Voucher voucher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoucherDetailScreen.newInstance(voucher),
      ),
    );
  }
}
