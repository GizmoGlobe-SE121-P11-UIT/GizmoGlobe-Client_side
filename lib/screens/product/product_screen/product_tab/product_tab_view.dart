import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/objects/product_related/product_extensions.dart';
import 'package:gizmoglobe_client/widgets/product/product_card.dart';

import '../../../../data/database/database.dart';
import '../../../../enums/processing/process_state_enum.dart';
import '../../../../enums/processing/sort_enum.dart';
import '../../../../enums/product_related/category_enum.dart';
import '../../../../enums/product_related/product_status_enum.dart';
import '../../../../objects/product_related/filter_argument.dart';
import '../../../../objects/product_related/product.dart';
import '../../../../widgets/general/app_text_style.dart';
import '../../filter/filter_screen/filter_screen_view.dart';
import '../../mixin/product_tab_mixin.dart';
import '../../product_detail/product_detail_view.dart';
import 'product_tab_cubit.dart';
import 'product_tab_state.dart';

class ProductTab extends StatefulWidget {
  const ProductTab({super.key});

  static Widget newInstance(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => AllTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newRam(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => RamTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newCpu(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => CpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newPsu(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => PsuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newGpu(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => GpuTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newDrive(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => DriveTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  static Widget newMainboard(
      {String? searchText, required List<Product> initialProducts}) =>
      BlocProvider<TabCubit>(
        create: (context) => MainboardTabCubit()
          ..initialize(const FilterArgument(),
              searchText: searchText, initialProducts: initialProducts),
        child: const ProductTab(),
      );

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab>
    with SingleTickerProviderStateMixin, TabMixin<ProductTab> {
  TabCubit get cubit => context.read<TabCubit>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              BlocBuilder<TabCubit, TabState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      Text(
                        'Sort By'
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<SortEnum>(
                          isExpanded: true,
                          itemHeight: kMinInteractiveDimension,
                          value: state.selectedSortOption,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          underline: Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          onChanged: (SortEnum? newValue) {
                            if (newValue != null &&
                                newValue != state.selectedSortOption) {
                              cubit.updateSortOption(newValue);
                            }
                          },
                          items: SortEnum.values
                              .map<DropdownMenuItem<SortEnum>>(
                                  (SortEnum value) {
                                String displayText;
                                switch (value) {
                                  case SortEnum.salesHighest:
                                    // displayText = S.of(context).salesHighest;
                                    displayText = 'Sales Highest';
                                    break;
                                  case SortEnum.salesLowest:
                                    // displayText = S.of(context).salesLowest;
                                    displayText = 'Sales Lowest';
                                    break;
                                  case SortEnum.releaseLatest:
                                    // displayText = S.of(context).releaseLatest;
                                    displayText = 'Release Latest';
                                    break;
                                  case SortEnum.releaseOldest:
                                    // displayText = S.of(context).releaseOldest;
                                    displayText = 'Release Oldest';
                                    break;
                                  case SortEnum.priceHighest:
                                    // displayText = S.of(context).priceHighest;
                                    displayText = 'Price Highest';
                                    break;
                                  case SortEnum.priceLowest:
                                    // displayText = S.of(context).stockLowest;
                                    displayText = 'Price Lowest';
                                    break;
                                }
                                return DropdownMenuItem<SortEnum>(
                                  value: value,
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 40),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      displayText,
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.filter_list_alt),
                          iconSize: 28,
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () async {
                            final FilterArgument arguments = state
                                .filterArgument
                                .copy(filter: state.filterArgument);

                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    FilterScreen.newInstance(
                                      arguments: arguments,
                                      selectedTabIndex: cubit.getIndex(),
                                      manufacturerList:
                                      cubit.getManufacturerList(),
                                    ),
                              ),
                            );

                            if (result is FilterArgument) {
                              cubit.updateFilter(
                                filter: result,
                              );
                              cubit.applyFilters();
                            }
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<TabCubit, TabState>(
                  builder: (context, state) {
                    if (state.filteredProductList.isEmpty) {
                      return Center(
                        child: Text(
                          // S.of(context).noProductsFound,
                          'No Products Found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                      childAspectRatio: 0.65,
                      children: List.generate(
                        state.filteredProductList.length,
                            (index) {
                          final product = state.filteredProductList[index];
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: state.selectedProduct == null || state.selectedProduct == product
                                ? 1.0
                                : 0.3,
                            child: ProductCard(
                              product: product,
                              onTap: () async {
                                cubit.setSelectedProduct(null);
                                ProcessState result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen.newInstance(product),
                                  ),
                                );
                                if (result == ProcessState.success) {
                                  await cubit.reloadProducts();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<TabCubit, TabState>(
          builder: (context, state) {
            if (state.processState == ProcessState.loading) {
              return Stack(
                children: [
                  ModalBarrier(
                      dismissible: false, color: Colors.black.withValues(alpha: 0.5)),
                  Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ]),
    );
  }
}
