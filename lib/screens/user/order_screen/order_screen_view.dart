import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/enums/processing/order_option_enum.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_tab/product_tab_view.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/user/order_screen/order_screen_state.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../objects/product_related/product.dart';
import '../../../widgets/dialog/information_dialog.dart';
import '../../../widgets/general/app_text_style.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/order/sales_invoice_widget.dart';

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

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  OrderScreenCubit get cubit => context.read<OrderScreenCubit>();
  late TabController tabController;

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
              Navigator.pop(context);
            },
            fillColor: Colors.transparent,
          ),
          title: const GradientText(text: 'Order'),
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabAlignment: TabAlignment.fill,
            indicator: const BoxDecoration(),
            tabs: [
              ...OrderOption.values.map((option) => Tab(
                text: option.toString(),
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
                    title: 'Confirmed',
                    content: 'The delivery has been confirmed.',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderScreen.newInstance(orderOption: OrderOption.completed),
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
                        ? const Center(
                      child: Text('No order is waiting to be shipped.', style: AppTextStyle.regularText),
                    ) : ListView.builder(
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
                        ? const Center(
                      child: Text('No order is waiting to be received.', style: AppTextStyle.regularText),
                    ) : ListView.builder(
                      itemCount: state.toReceiveList.length,
                      itemBuilder: (context, index) {
                        final salesInvoice = state.toReceiveList[index];
                        return SalesInvoiceWidget(
                          salesInvoice: salesInvoice,
                          onPressed: () async {
                            if (salesInvoice.salesStatus == SalesStatus.shipped) {
                              await cubit.confirmDelivery(salesInvoice);
                            }
                          },
                        );
                      },
                    ),
                    // Tab 3: Completed List
                    state.completedList.isEmpty
                        ? const Center(
                      child: Text('No order has been completed.', style: AppTextStyle.regularText),
                    ) : ListView.builder(
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