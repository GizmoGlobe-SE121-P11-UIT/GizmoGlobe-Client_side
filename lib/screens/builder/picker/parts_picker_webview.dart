import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_state.dart';
import 'package:gizmoglobe_client/widgets/general/field_with_icon.dart';

import 'package:gizmoglobe_client/services/recommendation/find_compatible.dart';

class PartsPickerWebView extends StatefulWidget {
  final CategoryEnum category;
  final Function(List<Product>) onProductsSelected;
  final bool allowMultipleSelection;
  final List<Product>? compatibleProducts;

  const PartsPickerWebView({
    super.key,
    required this.category,
    required this.onProductsSelected,
    this.allowMultipleSelection = false,
    this.compatibleProducts,
  });

  static Widget withCubit(
      PartsPickerCubit cubit, {
        required CategoryEnum category,
        required Function(List<Product>) onProductsSelected,
        bool allowMultipleSelection = false,
        List<Product>? compatibleProducts,
      }) =>
      BlocProvider.value(
        value: cubit,
        child: PartsPickerWebView(
          category: category,
          onProductsSelected: onProductsSelected,
          allowMultipleSelection: allowMultipleSelection,
          compatibleProducts: compatibleProducts,
        ),
      );

  @override
  State<PartsPickerWebView> createState() => _PartsPickerWebViewState();
}

class _PartsPickerWebViewState extends State<PartsPickerWebView> {
  PartsPickerCubit get cubit => context.read<PartsPickerCubit>();
  late TextEditingController searchController;
  late FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    cubit.loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Container(
        width: kIsWeb ? (isMobile ? double.infinity : 1200) : double.infinity,
        height: kIsWeb
            ? (isMobile ? MediaQuery.of(context).size.height * 0.85 : 800)
            : MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getCategoryLabel(context, widget.category),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 24),
            FieldWithIcon(
              height: 40,
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: S.of(context).findYourItem,
              fillColor: Theme.of(context).colorScheme.surface,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              onChanged: (value) {
                cubit.updateSearchText(searchController.text);
              },
              onSubmitted: (value) {
                searchFocusNode.unfocus();
              },
            ),
            SizedBox(height: isMobile ? 12 : 24),
            Expanded(
              child: BlocBuilder<PartsPickerCubit, PartsPickerState>(
                builder: (context, state) {
                  if (state.processState == ProcessState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var displayProducts = state.displayProducts;

                  if (widget.compatibleProducts != null &&
                      widget.compatibleProducts!.isNotEmpty) {
                    displayProducts = displayProducts.where((product) {
                      return widget.compatibleProducts!.every(
                              (compatibleProduct) => areProductsCompatible(
                              product, compatibleProduct));
                    }).toList();
                  }

                  if (displayProducts.isEmpty) {
                    return Center(
                      child: Text(
                        S.of(context).noProductsFound,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }

                  // Responsive columns like product screen
                  final crossAxisCount = screenWidth >= 1200
                      ? 5
                      : screenWidth >= 900
                      ? 4
                      : screenWidth >= 600
                      ? 3
                      : 2;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isMobile ? 8 : 16,
                      mainAxisSpacing: isMobile ? 8 : 16,
                      // Taller cards on mobile
                      childAspectRatio: isMobile ? 0.62 : 0.75,
                    ),
                    itemCount: displayProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayProducts[index];
                      final isSelected =
                      state.selectedProducts.contains(product);
                      return _SelectableProductCard(
                        product: product,
                        isSelected: isSelected,
                        allowMultipleSelection: widget.allowMultipleSelection,
                        onTap: () {
                          if (widget.allowMultipleSelection) {
                            cubit.toggleProductSelection(product);
                          } else {
                            widget.onProductsSelected([product]);
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.allowMultipleSelection)
              BlocBuilder<PartsPickerCubit, PartsPickerState>(
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã chọn: ${state.selectedProducts.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            if (state.selectedProducts.isNotEmpty)
                              TextButton(
                                onPressed: () => cubit.clearSelection(),
                                child: const Text('Xóa chọn'),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: state.selectedProducts.isNotEmpty
                                  ? () {
                                widget.onProductsSelected(
                                    state.selectedProducts);
                                Navigator.of(context).pop();
                              }
                                  : null,
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, CategoryEnum category) {
    switch (category) {
      case CategoryEnum.cpu:
        return S.of(context).cpu;
      case CategoryEnum.mainboard:
        return S.of(context).mainboard;
      case CategoryEnum.ram:
        return S.of(context).ram;
      case CategoryEnum.gpu:
        return S.of(context).gpu;
      case CategoryEnum.psu:
        return S.of(context).psu;
      case CategoryEnum.drive:
        return S.of(context).drive;
      default:
        return S.of(context).all;
    }
  }
}

class _SelectableProductCard extends StatefulWidget {
  final Product product;
  final bool isSelected;
  final bool allowMultipleSelection;
  final VoidCallback onTap;

  const _SelectableProductCard({
    required this.product,
    required this.isSelected,
    required this.allowMultipleSelection,
    required this.onTap,
  });

  @override
  State<_SelectableProductCard> createState() => _SelectableProductCardState();
}

class _SelectableProductCardState extends State<_SelectableProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          // Product card (without tap interception)
          WebProductCard(
            product: widget.product,
            showFavoriteIcon: false,
            showCartButton: false,
          ),
          // Hover overlay
          if (_isHovered && !widget.isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chọn',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Selected indicator
          if (widget.isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          // Selected checkmark
          if (widget.isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          // Transparent tap overlay on top to capture all taps
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
