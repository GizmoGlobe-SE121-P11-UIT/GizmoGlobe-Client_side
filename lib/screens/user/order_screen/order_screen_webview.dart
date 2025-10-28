import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import 'package:gizmoglobe_client/widgets/order/sales_invoice_widget.dart';
import '../../../enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/services/platform_actions.dart'
    as platform_actions;

class OrderScreenWebView extends StatefulWidget {
  final OrderOption? initialTab;

  const OrderScreenWebView({super.key, this.initialTab});

  static Widget newInstance({OrderOption? initialTab}) => BlocProvider(
        create: (context) => OrderScreenCubit(),
        child: OrderScreenWebView(initialTab: initialTab),
      );

  @override
  State<OrderScreenWebView> createState() => _OrderScreenWebViewState();
}

class _OrderScreenWebViewState extends State<OrderScreenWebView>
    with SingleTickerProviderStateMixin {
  OrderScreenCubit get cubit => context.read<OrderScreenCubit>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: OrderOption.values.length,
      vsync: this,
      initialIndex: widget.initialTab?.index ?? OrderOption.toShip.index,
    );

    // Initialize with the selected tab
    final initialOption = widget.initialTab ?? OrderOption.toShip;
    cubit.initialize(initialOption);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Web Header (only on web)
          if (kIsWeb) const WebHeader(),
          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Centered Title
                  Center(
                    child: Text(
                      S.of(context).orders,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab Bar - fixed height to prevent label clipping
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorWeight: 3,
                      labelPadding: EdgeInsets.zero,
                      tabAlignment: TabAlignment.fill,
                      dividerColor: Colors.transparent,
                      onTap: (index) {
                        // Update URL when tab changes
                        final option = OrderOption.values[index];
                        String tabName;
                        switch (option) {
                          case OrderOption.toShip:
                            tabName = 'to-ship';
                            break;
                          case OrderOption.toReceive:
                            tabName = 'to-receive';
                            break;
                          case OrderOption.completed:
                            tabName = 'completed';
                            break;
                        }
                        final newUrl = '/orders?tab=$tabName';
                        // Update the browser URL with hash for proper routing
                        if (kIsWeb) {
                          platform_actions.setHashUrl(newUrl);
                        }
                      },
                      tabs: OrderOption.values
                          .map((option) => Tab(
                                child: Center(
                                  child: Text(
                                    _getTabTitle(context, option),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Content
                  Expanded(
                    child: BlocConsumer<OrderScreenCubit, OrderScreenState>(
                      listener: (context, state) {
                        if (state.processState == ProcessState.success) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              title: Text(
                                S.of(context).orderConfirmed,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                S.of(context).deliveryConfirmed,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OrderScreenWebView.newInstance(
                                          initialTab: OrderOption.completed,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(S.of(context).ok),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // To Ship Tab
                            _buildTabContent(
                              state.toShipList,
                              S.of(context).noOrdersToShip,
                            ),
                            // To Receive Tab
                            _buildTabContent(
                              state.toReceiveList,
                              S.of(context).noOrdersToReceive,
                              enableConfirmDelivery: true,
                            ),
                            // Completed Tab
                            _buildTabContent(
                              state.completedList,
                              S.of(context).noCompletedOrders,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    List<dynamic> orders,
    String emptyMessage, {
    bool enableConfirmDelivery = false,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).yourOrdersWillAppearHere,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final salesInvoice = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SalesInvoiceWidget(
            salesInvoice: salesInvoice,
            onPressed: () async {
              if (enableConfirmDelivery &&
                  salesInvoice.salesStatus?.toString() == 'shipped') {
                await cubit.confirmDelivery(salesInvoice);
              }
            },
          ),
        );
      },
    );
  }
}
