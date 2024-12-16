import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/screens/home/product_list_search/product_list_search_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_logo.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';
import '../../../widgets/filter/filter/product_filter.dart';
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
  ProductListSearchCubit get cubit => context.read<ProductListSearchCubit>();

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.initialSearchText);
    cubit.initialize(widget.initialSearchText);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: GradientIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GradientIconButton(
                      icon: Icons.filter_list,
                      iconSize: 20,

                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProductFilterScreen(),
                          ),
                        );
                        if (result != null) {
                          cubit.applyFilters(
                            result['category'],
                            result['manufacturer'],
                            result['minPrice'],
                            result['maxPrice'],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: FieldWithIcon(
                            controller: searchController,
                            hintText: 'What do you need?',
                            fillColor: Theme.of(context).colorScheme.surface,
                            onChange: (value) => {
                              cubit.changeSearchText(value)
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GradientIconButton(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          onPressed: () {
                            cubit.searchProducts(searchController.text);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<ProductListSearchCubit, ProductListSearchState>(
                        builder: (context, state) {
                          if (state.productList.isEmpty) {
                            return const Center(
                              child: Text('No products match that filter'),
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
          ],
        ),
      ),
    );
  }
}