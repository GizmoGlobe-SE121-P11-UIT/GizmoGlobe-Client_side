import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../enums/processing/sort_enum.dart';
import '../../../../objects/product_related/filter_argument.dart';
import '../../../../objects/product_related/product.dart';
import '../../../../widgets/general/app_text_style.dart';
import '../../../../widgets/product/product_card.dart';
import '../../filter/filter_screen/filter_screen_view.dart';
import '../../mixin/product_tab_mixin.dart';
import 'product_tab_cubit.dart';
import 'product_tab_state.dart';

class ProductTab extends StatefulWidget {
  const ProductTab({super.key});

  static Widget newInstance({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => AllTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newRam({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => RamTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newCpu({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => CpuTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newPsu({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => PsuTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newGpu({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => GpuTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newDrive({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => DriveTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  static Widget newMainboard({String? searchText, List<Product>? initialProducts, required SortEnum initialSortOption}) => BlocProvider<TabCubit>(
    create: (context) => MainboardTabCubit()..initialize(const FilterArgument(), searchText: searchText, initialProducts: initialProducts, initialSortOption: initialSortOption),
    child: const ProductTab(),
  );

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab> with SingleTickerProviderStateMixin, TabMixin<ProductTab> {
  TabCubit get cubit => context.read<TabCubit>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              BlocBuilder<TabCubit, TabState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      const Text(
                        'Sort by: ', // 'Sắp xếp theo: '
                        style: AppTextStyle.smallText,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<SortEnum>(
                        value: state.selectedSortOption,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onChanged: (SortEnum? newValue) {
                          if (newValue != null && newValue != state.selectedSortOption) {
                            cubit.updateSortOption(newValue);
                          }
                        },
                        items: SortEnum.values.map<DropdownMenuItem<SortEnum>>((SortEnum value) {
                          return DropdownMenuItem<SortEnum>(
                            value: value,
                            child: Row(
                              children: [
                                Text(value.toString()), // Các giá trị enum cần được dịch trong enum class
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      Center(
                        child: GradientIconButton(
                          icon: Icons.filter_list_alt,
                          iconSize: 28,
                          onPressed: () async {
                            final FilterArgument arguments = state.filterArgument.copy(
                              filter: state.filterArgument
                            );

                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FilterScreen.newInstance(
                                  arguments: arguments,
                                  selectedTabIndex: cubit.getIndex(),
                                  manufacturerList: cubit.getManufacturerList(),
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
                      return const Center(
                        child: Text('No products found'), // 'Không tìm thấy sản phẩm'
                      );
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        childAspectRatio: 0.75, // Adjust the aspect ratio as needed
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: state.filteredProductList.length,
                      itemBuilder: (context, index) {
                        final product = state.filteredProductList[index];
                        return ProductCard(product: product);
                      },
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
                    ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.5)),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ]
      ),
    );
  }
}