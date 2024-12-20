import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/screens/home/product_list_search/product_list_search_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/checkbox_button.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../../enums/processing/sort_enum.dart';
import '../../../widgets/filter/advanced_filter_search/advanced_filter_search_view.dart';
import '../../../widgets/general/app_text_style.dart';
import '../../../widgets/general/gradient_radio_button.dart';
import 'product_list_search_cubit.dart';

class ProductListSearchScreen extends StatefulWidget {
  final String initialSearchText;

  const ProductListSearchScreen({super.key, required this.initialSearchText});

  static Widget newInstance({required String initialSearchText}) =>
      BlocProvider(
        create: (context) => ProductListSearchCubit(),
        child: ProductListSearchScreen(initialSearchText: initialSearchText),
      );

  @override
  State<ProductListSearchScreen> createState() => _ProductListSearchScreenState();
}

class _ProductListSearchScreenState extends State<ProductListSearchScreen> {
  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  ProductListSearchCubit get cubit => context.read<ProductListSearchCubit>();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.initialSearchText);
    searchFocusNode = FocusNode();
    cubit.initialize(widget.initialSearchText);
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
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
            icon: Icons.arrow_back,
            onPressed: () {
              Navigator.of(context).pop();
            },
            fillColor: Colors.transparent,
          ),

          title: FieldWithIcon(
            controller: searchController,
            focusNode: searchFocusNode,
            hintText: 'What do you need?',
            fillColor: Theme.of(context).colorScheme.surface,
          ),

          actions: [
            GradientIconButton(
              icon: FontAwesomeIcons.magnifyingGlass,
              iconSize: 28,
              onPressed: () {
                cubit.updateFilter();
                cubit.applyFilters();
              },
              fillColor: Colors.transparent,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              BlocBuilder<ProductListSearchCubit, ProductListSearchState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      CheckboxButton(
                        text: SortEnum.bestSeller.toString(),
                        onSelected: () {
                          cubit.updateSortOption(SortEnum.bestSeller);
                          cubit.applyFilters();
                        },
                        padding: const EdgeInsets.all(8),
                        textStyle: AppTextStyle.smallText,
                        isSelected: state.selectedOption == SortEnum.bestSeller,
                      ),
                      const SizedBox(width: 8),

                      CheckboxButton(
                        text: SortEnum.lowestPrice.toString(),
                        onSelected: () {
                          cubit.updateSortOption(SortEnum.lowestPrice);
                          cubit.applyFilters();
                        },
                        padding: const EdgeInsets.all(8),
                        textStyle: AppTextStyle.smallText,
                        isSelected: state.selectedOption == SortEnum.lowestPrice,
                      ),
                      const SizedBox(width: 8),

                      CheckboxButton(
                        text: SortEnum.highestPrice.toString(),
                        onSelected: () {
                          cubit.updateSortOption(SortEnum.highestPrice);
                          cubit.applyFilters();
                        },
                        padding: const EdgeInsets.all(8),
                        textStyle: AppTextStyle.smallText,
                        isSelected: state.selectedOption == SortEnum.highestPrice,
                      ),

                      Expanded(
                        child: Center(
                          child: GradientIconButton(
                            icon: Icons.filter_list_alt,
                            iconSize: 28,
                            onPressed: () async {
                              final FilterSearchArguments arguments = FilterSearchArguments(
                                selectedCategories: state.selectedCategoryList,
                                selectedManufacturers: state.selectedManufacturerList,
                                minPrice: state.minPrice,
                                maxPrice: state.maxPrice,
                              );

                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdvancedFilterSearchScreen.newInstance(
                                        arguments: arguments,
                                      ),
                                ),
                              );

                              if (result is FilterSearchArguments) {
                                cubit.updateFilter(
                                  selectedCategoryList: result.selectedCategories,
                                  selectedManufacturerList: result.selectedManufacturers,
                                  minPrice: result.minPrice,
                                  maxPrice: result.maxPrice,
                                );
                                cubit.applyFilters();
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child: BlocBuilder<ProductListSearchCubit, ProductListSearchState>(
                  builder: (context, state) {
                    if (state.productList.isEmpty) {
                      return const Center(
                        child: Text('No products found'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.productList.length,
                      itemBuilder: (context, index) {
                        final product = state.productList[index];
                        return ListTile(
                          title: Text(product.productName),
                          subtitle: Text('đ${product.price}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}