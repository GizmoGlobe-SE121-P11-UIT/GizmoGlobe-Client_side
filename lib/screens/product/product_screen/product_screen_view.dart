import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/enums/processing/sort_enum.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_screen_state.dart';
import 'package:gizmoglobe_client/screens/product/product_screen/product_tab/product_tab_view.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../../enums/product_related/category_enum.dart';
import '../../../objects/product_related/product.dart';

class ProductScreen extends StatefulWidget {
  final List<Product>? initialProducts;
  final SortEnum? initialSortOption;

  const ProductScreen({super.key, this.initialProducts, this.initialSortOption});

  static Widget newInstance({List<Product>? initialProducts, SortEnum? initialSortOption}) => BlocProvider(
    create: (context) => ProductScreenCubit(),
    child: ProductScreen(initialProducts: initialProducts, initialSortOption: initialSortOption),
  );

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> with SingleTickerProviderStateMixin {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  ProductScreenCubit get cubit => context.read<ProductScreenCubit>();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    tabController = TabController(length: CategoryEnum.values.length + 1, vsync: this);
    cubit.initialize(widget.initialProducts ?? [], widget.initialSortOption ?? SortEnum.releaseLatest);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int getTabCount() => CategoryEnum.values.length + 1;

  void onTabChanged(int index) {
    cubit.updateSelectedTabIndex(index);
  }

  Future<bool> _onWillPop() async {
    if (searchFocusNode.hasFocus) {
      searchFocusNode.unfocus();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: FieldWithIcon(
              height: 40,
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: 'Find your item',
              fillColor: Theme.of(context).colorScheme.surface,
              prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
              onChanged: (value) {
                cubit.updateSearchText(searchController.text);
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s-]')),
              ],
            ),
            bottom: TabBar(
              controller: tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              indicator: const BoxDecoration(),
              tabs: [
                const Tab(text: 'All'),
                ...CategoryEnum.values.map((category) => Tab(
                  text: category.toString().split('.').last,
                )),
              ],
            ),
          ),
          body: SafeArea(
            child: BlocBuilder<ProductScreenCubit, ProductScreenState>(
              builder: (context, state) {
                return TabBarView(
                  controller: tabController,
                  children: [
                    ProductTab.newInstance(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newRam(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newCpu(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newPsu(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newGpu(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newDrive(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                    ProductTab.newMainboard(searchText: state.searchText, initialProducts: state.initialProducts, initialSortOption: state.initialSortOption),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}