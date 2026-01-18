import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_webview.dart';
import 'package:gizmoglobe_client/screens/user/order_detail_screen/order_detail_view.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/rating_order/rate_order_view.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../generated/l10n.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/app_text_style.dart';
import '../../../objects/invoice_related/sales_invoice.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/order/sales_invoice_widget.dart';
import '../../main/main_screen/main_screen_view.dart';

import '../../../objects/invoice_related/rating.dart';
import '../../../data/database/database.dart';

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

  List<Rating> _userRatings = [];

  void _handleTabChange() {
    if (!tabController.indexIsChanging) {
      final selectedOption = OrderOption.values[tabController.index];
      cubit.initialize(selectedOption);
    }
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
  void initState() {
    super.initState();
    tabController = TabController(
      length: OrderOption.values.length,
      vsync: this,
      initialIndex: widget.orderOption.index,
    );
    tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.initialize(widget.orderOption);
      _loadUserRatings();
    });
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.dispose();
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
                  builder: (context) => const MainScreen(initialIndex: 4),
                ),
                (route) => false,
              );
            },
            fillColor: Colors.transparent,
          ),
          title: GradientText(text: S.of(context).orders),
        ),
        body: SafeArea(
          child: BlocConsumer<OrderScreenCubit, OrderScreenState>(
            listener: (context, state) {
              if (state.processState == ProcessState.success) {
                cubit.resetProcessState();
                showDialog(
                  context: context,
                  builder: (context) => InformationDialog(
                    title: S.of(context).orderConfirmed,
                    content: S.of(context).deliveryConfirmed,
                    onPressed: () {
                      Navigator.of(context).pop();
                      tabController.animateTo(OrderOption.completed.index);
                      cubit.initialize(OrderOption.completed);
                    },
                  ),
                );
              }
            },
            builder: (context, state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth > 500 ? 32.0 : 16.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        _buildTabNavigation(context),
                        const SizedBox(height: 24),
                        Expanded(
                          child: TabBarView(
                            controller: tabController,
                            children: [
                              _buildInvoiceList(
                                context: context,
                                invoices: state.toShipList,
                                emptyLabel: S.of(context).noOrdersToShip,
                                cubit: cubit,
                                enableButton: false,
                              ),
                              _buildInvoiceList(
                                context: context,
                                invoices: state.toReceiveList,
                                emptyLabel: S.of(context).noOrdersToReceive,
                                cubit: cubit,
                                enableButton: true,
                              ),
                              _buildInvoiceList(
                                context: context,
                                invoices: state.completedList,
                                emptyLabel: S.of(context).noCompletedOrders,
                                cubit: cubit,
                                enableButton: true,
                              ),
                              _buildInvoiceList(
                                context: context,
                                invoices: state.cancelledList,
                                emptyLabel: S.of(context).noCancelledOrders,
                                cubit: cubit,
                                enableButton: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation(BuildContext context) {
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
        controller: tabController,
        tabAlignment: TabAlignment.start,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
        indicator: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(32),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor:
            WidgetStateProperty.resolveWith((_) => Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        dividerColor: Colors.transparent,
        isScrollable: true,
        tabs: OrderOption.values
            .map(
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _getTabTitle(context, option),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInvoiceList({
    required BuildContext context,
    required List<SalesInvoice> invoices,
    required String emptyLabel,
    required OrderScreenCubit cubit,
    required bool enableButton,
  }) {
    if (invoices.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: AppTextStyle.regularText,
        ),
      );
    }

    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        SalesInvoice salesInvoice = invoices[index];
        return SalesInvoiceWidget(
          salesInvoice: salesInvoice,
          userRatings: _userRatings,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailView.newInstance(
                  salesInvoice: salesInvoice,
                ),
              ),
            );
          },
          onRate: (String productId) async {
            final invoiceId = salesInvoice.salesInvoiceID ?? '';
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RateOrderView.newInstance(
                  invoiceId: invoiceId,
                  productId: productId,
                ),
              ),
            );

            if (!mounted) return;

            await _loadUserRatings();
            await cubit.completeInvoiceIfAllProductsRated(
              salesInvoice,
              _userRatings,
            );
            cubit.initialize(OrderOption.values[tabController.index]);
          },
          onPressed: () async {
            if (enableButton &&
                salesInvoice.salesStatus == SalesStatus.shipped) {
              await cubit.confirmDelivery(salesInvoice);
            }
          },
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
