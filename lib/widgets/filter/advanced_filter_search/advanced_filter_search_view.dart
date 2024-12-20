import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/widgets/filter/advanced_filter_search/advanced_filter_search_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import '../manufacturer_filter/manufacturer_filter.dart';
import '../option_filter/option_filter.dart';
import '../range_filter/range_filter.dart';
import 'advanced_filter_search_cubit.dart';

class AdvancedFilterSearchScreen extends StatefulWidget {
  final FilterSearchArguments arguments;

  const AdvancedFilterSearchScreen({
    super.key,
    required this.arguments,
  });

  static newInstance({
    required arguments,
  }) =>
      BlocProvider(
        create: (context) => AdvancedFilterSearchCubit(),
        child: AdvancedFilterSearchScreen(
          arguments: arguments,
        ),
      );

  @override
  State<AdvancedFilterSearchScreen> createState() => _AdvancedFilterSearchScreenState();
}

class _AdvancedFilterSearchScreenState extends State<AdvancedFilterSearchScreen> {
  AdvancedFilterSearchCubit get cubit => context.read<AdvancedFilterSearchCubit>();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fromController.text = widget.arguments.minPrice ?? '';
    toController.text = widget.arguments.maxPrice ?? '';
    cubit.initialize(
      initialSelectedCategories: widget.arguments.selectedCategories,
      initialSelectedManufacturers: widget.arguments.selectedManufacturers,
      initialMinPrice: widget.arguments.minPrice,
      initialMaxPrice: widget.arguments.maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdvancedFilterSearchCubit, AdvancedFilterSearchState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Text('Filter', style: AppTextStyle.bigText),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    FilterSearchArguments(
                      selectedCategories: state.selectedCategories,
                      selectedManufacturers: state.selectedManufacturers,
                      minPrice: state.minPrice,
                      maxPrice: state.maxPrice,
                    ),
                  );
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptionFilterView<CategoryEnum>(
                  name: 'Category',
                  enumValues: CategoryEnum.values,
                  selectedValues: state.selectedCategories,
                  onToggleSelection: cubit.toggleCategory,
                ),
                const SizedBox(height: 16.0),

                ManufacturerFilter(
                  selectedManufacturers: state.selectedManufacturers,
                  onToggleSelection: cubit.toggleManufacturer,
                ),
                const SizedBox(height: 16.0),

                RangeFilter(
                  name: 'Price',
                  fromController: fromController,
                  toController: toController,
                  onFromValueChanged: (value) {
                    cubit.updateMinPrice(value);
                  },
                  onToValueChanged: (value) {
                    cubit.updateMaxPrice(value);
                  },
                  fromValue: state.minPrice,
                  toValue: state.maxPrice,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FilterSearchArguments {
  final List<CategoryEnum> selectedCategories;
  final List<Manufacturer> selectedManufacturers;
  final String? minPrice;
  final String? maxPrice;

  FilterSearchArguments({
    required this.selectedCategories,
    required this.selectedManufacturers,
    this.minPrice,
    this.maxPrice,
  });
}