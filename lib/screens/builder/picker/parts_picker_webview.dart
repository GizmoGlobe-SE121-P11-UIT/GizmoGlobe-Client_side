import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';
import 'package:gizmoglobe_client/components/general/web_product_card.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_state.dart';

class PartsPickerWebView extends StatefulWidget {
  final CategoryEnum category;
  final Function(Product) onProductSelected;

  const PartsPickerWebView({
    super.key,
    required this.category,
    required this.onProductSelected,
  });

  static Widget withCubit(
    PartsPickerCubit cubit, {
    required CategoryEnum category,
    required Function(Product) onProductSelected,
  }) =>
      BlocProvider.value(
        value: cubit,
        child: PartsPickerWebView(
          category: category,
          onProductSelected: onProductSelected,
        ),
      );

  @override
  State<PartsPickerWebView> createState() => _PartsPickerWebViewState();
}

class _PartsPickerWebViewState extends State<PartsPickerWebView> {
  PartsPickerCubit get cubit => context.read<PartsPickerCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (kIsWeb) const WebHeader(),
          Expanded(
            child: BlocBuilder<PartsPickerCubit, PartsPickerState>(
              builder: (context, state) {
                if (state.processState == ProcessState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryLabel(widget.category),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return GestureDetector(
                              onTap: () => widget.onProductSelected(product),
                              child: WebProductCard(product: product),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
}
