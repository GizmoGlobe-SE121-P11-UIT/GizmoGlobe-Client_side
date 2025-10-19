import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_webview.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../generated/l10n.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/app_text_style.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/order/sales_invoice_widget.dart';
import '../../main/main_screen/main_screen_view.dart';

class OrderScreen extends StatefulWidget {
  final OrderOption orderOption;

  const OrderScreen({super.key, required this.orderOption});

  static Widget newInstance({required OrderOption orderOption}) => BlocProvider(
        create: (context) => OrderScreenCubit(),
        child: OrderScreen(orderOption: orderOption),
      );

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  OrderScreenCubit get cubit => context.read<OrderScreenCubit>();
  late TabController tabController;

  String _getTabTitle(BuildContext context, OrderOption option) {
    switch (option) {
      case OrderOption.toShip:
        return S.of(context).toShip;
      case OrderOption.toReceive:
        return S.of(context).toReceive;
      case OrderOption.completed:
        return S.of(context).completed;
    }
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: OrderOption.values.length,
      vsync: this,
      initialIndex: widget.orderOption.index,
    );
    cubit.initialize(widget.orderOption);
  }

  @override
  Widget build(BuildContext context) {
    // For web, use the webview component directly
    if (kIsWeb) {
      return OrderScreenWebView.newInstance(initialTab: widget.orderOption);
    }

    // For mobile, use the original layout
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: GradientIconButton(
            icon: Icons.chevron_left,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(initialIndex: 3),
                ),
                (route) => false,
              );
            },
            fillColor: Colors.transparent,
          ),
          title: GradientText(text: S.of(context).orders),
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.fill,
            indicator: const BoxDecoration(),
            tabs: [
              ...OrderOption.values.map((option) => Tab(
                    text: _getTabTitle(context, option),
                  )),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<OrderScreenCubit, OrderScreenState>(
            listener: (context, state) {
              if (state.processState == ProcessState.success) {
                showDialog(
                  context: context,
                  builder: (context) => InformationDialog(
                    title: S.of(context).orderConfirmed,
                    content: S.of(context).deliveryConfirmed,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderScreen.newInstance(
                              orderOption: OrderOption.completed),
                        ),
                      );
                    },
                  ),
                );
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Tab 1: To Ship List
                    state.toShipList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noOrdersToShip,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.toShipList.length,
                            itemBuilder: (context, index) {
                              final salesInvoice = state.toShipList[index];
                              return SalesInvoiceWidget(
                                salesInvoice: salesInvoice,
                                onPressed: () {},
                              );
                            },
                          ),
                    // Tab 2: To Receive List
                    state.toReceiveList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noOrdersToReceive,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.toReceiveList.length,
                            itemBuilder: (context, index) {
                              final salesInvoice = state.toReceiveList[index];
                              return SalesInvoiceWidget(
                                salesInvoice: salesInvoice,
                                onPressed: () async {
                                  if (salesInvoice.salesStatus ==
                                      SalesStatus.shipped) {
                                    await cubit.confirmDelivery(salesInvoice);
                                  }
                                },
                              );
                            },
                          ),
                    // Tab 3: Completed List
                    state.completedList.isEmpty
                        ? Center(
                            child: Text(
                              S.of(context).noCompletedOrders,
                              style: AppTextStyle.regularText,
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.completedList.length,
                            itemBuilder: (context, index) {
                              final salesInvoice = state.completedList[index];
                              return SalesInvoiceWidget(
                                salesInvoice: salesInvoice,
                                onPressed: () {},
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