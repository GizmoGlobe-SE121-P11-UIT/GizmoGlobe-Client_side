import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/firebase/firebase.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/objects/product_related/product_image.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_state.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_webview.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/functions/helper.dart';

class PartsPickerScreen extends StatefulWidget {
  final CategoryEnum category;
  final Function(List<Product>) onProductsSelected;
  final bool allowMultipleSelection;

  const PartsPickerScreen({
    super.key,
    required this.category,
    required this.onProductsSelected,
    this.allowMultipleSelection = false,
  });

  static Widget newInstance({
    required CategoryEnum category,
    required Function(List<Product>) onProductsSelected,
    bool allowMultipleSelection = false,
  }) =>
      BlocProvider(
        create: (context) => PartsPickerCubit(category),
        child: PartsPickerScreen(
          category: category,
          onProductsSelected: onProductsSelected,
          allowMultipleSelection: allowMultipleSelection,
        ),
      );

  @override
  State<PartsPickerScreen> createState() => _PartsPickerScreenState();
}

class _PartsPickerScreenState extends State<PartsPickerScreen> {
  PartsPickerCubit get cubit => context.read<PartsPickerCubit>();

  @override
  void initState() {
    super.initState();
    cubit.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return PartsPickerWebView.withCubit(
        cubit,
        category: widget.category,
        onProductsSelected: widget.onProductsSelected,
        allowMultipleSelection: widget.allowMultipleSelection,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryLabel(widget.category)),
        actions: [
          if (widget.allowMultipleSelection)
            BlocBuilder<PartsPickerCubit, PartsPickerState>(
              buildWhen: (p, c) =>
                  p.selectedProducts.length != c.selectedProducts.length,
              builder: (context, state) {
                return TextButton(
                  onPressed: state.selectedProducts.isNotEmpty
                      ? () => cubit.clearSelection()
                      : null,
                  child: Text(
                    S.of(context).clearAll,
                    style: TextStyle(
                      color: state.selectedProducts.isNotEmpty
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<PartsPickerCubit, PartsPickerState>(
        builder: (context, state) {
          if (state.processState == ProcessState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.products.isEmpty) {
            return Center(
              child: Text(
                S.of(context).noProductsFound,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    final isSelected = state.selectedProducts.contains(product);
                    return _MobileProductCard(
                      product: product,
                      isSelected: isSelected,
                      showSelectionBadge: widget.allowMultipleSelection,
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
                ),
              ),
              if (widget.allowMultipleSelection)
                _buildSelectionBar(context, state),
            ],
          );
        },
      ),
    );
  }

  String _getCategoryLabel(CategoryEnum category) {
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

  Widget _buildSelectionBar(BuildContext context, PartsPickerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${S.of(context).itemsCount(state.selectedProducts.length)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: state.selectedProducts.isNotEmpty
                    ? () => cubit.clearSelection()
                    : null,
                child: Text(S.of(context).clearAll),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: state.selectedProducts.isNotEmpty
                    ? () {
                        widget.onProductsSelected(state.selectedProducts);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Text(S.of(context).confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool showSelectionBadge;
  final VoidCallback onTap;

  const _MobileProductCard({
    required this.product,
    required this.isSelected,
    required this.showSelectionBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.productID != null
                        ? FutureBuilder<ProductImage?>(
                            future: Firebase()
                                .getProductPrimaryImage(product.productID!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  !snapshot.hasData ||
                                  snapshot.data == null ||
                                  snapshot.data!.url.isEmpty) {
                                return Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant
                                      .withOpacity(0.4),
                                  child: Center(
                                    child: Icon(
                                      Icons.memory,
                                      size: 42,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                );
                              }
                              return Image.network(
                                snapshot.data!.url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.4),
                                    child: Center(
                                      child: Icon(
                                        Icons.memory,
                                        size: 42,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.4),
                            child: Center(
                              child: Icon(
                                Icons.memory,
                                size: 42,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Helper.toCurrencyFormat(
                            product.discountedPrice.toInt()),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showSelectionBadge)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.add,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
