import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import 'package:gizmoglobe_client/widgets/order/sales_invoice_widget.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_webview.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/rating_order/rate_order_webview.dart';
import 'package:gizmoglobe_client/objects/invoice_related/rating.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
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
  bool _initialSynced = false;
  List<Rating> _userRatings = [];

  void _handleTabChange() {
    if (!_initialSynced) return;
    if (_tabController.indexIsChanging) return;
    final selectedOption = OrderOption.values[_tabController.index];
    cubit.initialize(selectedOption);
    _updateUrlForTab(_tabController.index);
  }

  @override
  void initState() {
    super.initState();

    // Determine initial tab from URL if available
    final rawInitialTabIndex =
        widget.initialTab?.index ?? _getInitialTabFromUrl();
    final initialTabIndex = rawInitialTabIndex.clamp(
      0,
      OrderOption.values.length - 1,
    );
    _tabController = TabController(
      length: OrderOption.values.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );

    // Add listener to update URL when tab changes
    _tabController.addListener(_handleTabChange);

    // Re-sync once after first frame in case the hash/path arrives slightly later
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncedIndex = _getInitialTabFromUrl().clamp(
        0,
        OrderOption.values.length - 1,
      );
      if (_tabController.index != syncedIndex) {
        _tabController.index = syncedIndex;
      }
      cubit.initialize(OrderOption.values[syncedIndex]);
      _updateUrlForTab(syncedIndex);
      _loadUserRatings();
      setState(() {
        _initialSynced = true;
      });
    });
  }

  int _getInitialTabFromUrl() {
    if (!kIsWeb) return OrderOption.toShip.index;

    // Inspect query, hash, and path to determine initial tab on first load
    final uri = Uri.base;
    final tabParam = uri.queryParameters['tab']?.toLowerCase();
    if (tabParam != null) {
      if (tabParam.contains('cancel')) return OrderOption.cancelled.index;
      if (tabParam.contains('complete')) return OrderOption.completed.index;
      if (tabParam.contains('receive')) return OrderOption.toReceive.index;
      if (tabParam.contains('ship')) return OrderOption.toShip.index;
      final parsed = int.tryParse(tabParam);
      if (parsed != null && parsed >= 0 && parsed < OrderOption.values.length) {
        return parsed;
      }
    }

    final hashPath = platform_actions.getHashPath().toLowerCase();
    final fragment = uri.fragment.toLowerCase();
    final path = uri.path.toLowerCase();
    final combined =
        '$path$fragment$hashPath'.replaceAll('_', '-').replaceAll('//', '/');

    if (combined.contains('cancel')) return OrderOption.cancelled.index;
    if (combined.contains('complete')) return OrderOption.completed.index;
    if (combined.contains('receive')) return OrderOption.toReceive.index;
    if (combined.contains('ship')) return OrderOption.toShip.index;

    return OrderOption.toShip.index;
  }

  void _updateUrlForTab(int tabIndex) {
    if (!kIsWeb) return;

    final option = OrderOption.values[tabIndex];
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
      case OrderOption.cancelled:
        tabName = 'cancelled';
        break;
    }

    final newUrl = '/orders/$tabName';
    platform_actions.replaceHashUrl(newUrl);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
      case OrderOption.cancelled:
        return S.of(context).cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive horizontal padding
    final horizontalPadding = screenWidth < 600
        ? 16.0
        : screenWidth < 900
            ? 24.0
            : 32.0;

    return Scaffold(
      body: Container(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.15),
        child: Column(
          children: [
            if (kIsWeb) const WebHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          S.of(context).orders,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        _buildTabNavigation(context),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildTabBody(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final tabBackground =
        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            );
    final indicatorColor = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tabBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 13 : null,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 13 : null,
            ),
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(32),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor:
            WidgetStateProperty.resolveWith((_) => Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        isScrollable: isMobile,
        tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
        tabs: OrderOption.values
            .map(
              (option) => Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: isMobile ? 8 : 0,
                ),
                child: Text(
                  _getTabTitle(context, option),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : null,
                      ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabBody() {
    return BlocConsumer<OrderScreenCubit, OrderScreenState>(
      listener: (context, state) {
        if (state.processState == ProcessState.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                S.of(context).orderConfirmed,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: Text(
                S.of(context).deliveryConfirmed,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(OrderOption.completed.index);
                    cubit.initialize(OrderOption.completed);
                    _updateUrlForTab(OrderOption.completed.index);
                    cubit.resetProcessState();
                  },
                  child: Text(S.of(context).ok),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  state.toShipList,
                  S.of(context).noOrdersToShip,
                ),
                _buildTabContent(
                  state.toReceiveList,
                  S.of(context).noOrdersToReceive,
                  enableConfirmDelivery: true,
                ),
                _buildTabContent(
                  state.completedList,
                  S.of(context).noCompletedOrders,
                ),
                _buildTabContent(
                  state.cancelledList,
                  S.of(context).noCancelledOrders,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(
    List<SalesInvoice> orders,
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
            userRatings: _userRatings,
            onTap: () => OrderDetailWebView.show(
              context,
              salesInvoice: salesInvoice,
            ),
            onRate: (String productId) async {
              final invoiceId = salesInvoice.salesInvoiceID ?? '';
              final result = await RateOrderWebView.show(
                context: context,
                invoiceId: invoiceId,
                productId: productId,
              );

              if (!mounted) return;

              if (result == true) {
                await _loadUserRatings();
                await cubit.completeInvoiceIfAllProductsRated(
                  salesInvoice,
                  _userRatings,
                );
                cubit.initialize(OrderOption.values[_tabController.index]);
              }
            },
            onPressed: () async {
              if (enableConfirmDelivery &&
                  salesInvoice.salesStatus == SalesStatus.shipped) {
                await cubit.confirmDelivery(salesInvoice);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _loadUserRatings() async {
    try {
      final userId = Database().userID.isEmpty
          ? (await Database().getCurrentUserID() ?? '')
          : Database().userID;
      await Database().getRating();
      final ratings = userId.isEmpty ? <Rating>[] : Database().ratingList;
      if (mounted) setState(() => _userRatings = ratings);
    } catch (e) {
      rethrow;
    }
  }
}
