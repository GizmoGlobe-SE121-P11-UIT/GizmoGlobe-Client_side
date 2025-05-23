import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/voucher/list/voucher_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_view.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../widgets/dialog/information_dialog.dart';
import '../../../../widgets/general/app_text_style.dart';
import '../../../../widgets/voucher/voucher_widget.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  static Widget newInstance() => BlocProvider(
    create: (context) => VoucherScreenCubit(),
    child: const VoucherScreen(),
  );

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
    tabController = TabController(
      length: 2, // Changed from 4 to 2 tabs
      vsync: this,
      initialIndex: 0,
    );
    cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const GradientText(text: "Voucher"),
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.fill,
            indicator: const BoxDecoration(),
            tabs: const [
              Tab(text: 'Ongoing'),
              Tab(text: 'Upcoming'),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<VoucherScreenCubit, VoucherScreenState>(
            listener: (context, state) {
              if (state.processState == ProcessState.success) {
                showDialog(
                  context: context,
                  builder: (context) => InformationDialog(
                    title: state.dialogName.description,
                    content: state.dialogMessage,
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => VoucherScreen.newInstance())
                      );
                    },
                  ),
                );
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Tab 1: Ongoing voucher list
                    state.ongoingList.isEmpty
                        ? const Center(
                      child: Text(
                        'No vouchers available',
                        style: AppTextStyle.regularText,
                      ),
                    )
                        : ListView.builder(
                      itemCount: state.ongoingList.length,
                      itemBuilder: (context, index) {
                        final voucher = state.ongoingList[index];
                        return VoucherWidget(
                          voucher: voucher,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoucherDetailScreen.newInstance(voucher),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Tab 2: Upcoming voucher list
                    state.upcomingList.isEmpty
                        ? const Center(
                      child: Text(
                        'No vouchers available',
                        style: AppTextStyle.regularText,
                      ),
                    )
                        : ListView.builder(
                      itemCount: state.upcomingList.length,
                      itemBuilder: (context, index) {
                        final voucher = state.upcomingList[index];
                        return VoucherWidget(
                          voucher: voucher,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoucherDetailScreen.newInstance(voucher),
                              ),
                            );
                          },
                        );
                      },
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
}