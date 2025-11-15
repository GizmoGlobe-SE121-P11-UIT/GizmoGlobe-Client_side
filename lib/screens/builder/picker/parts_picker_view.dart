import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_cubit.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_state.dart';
import 'package:gizmoglobe_client/screens/builder/picker/parts_picker_webview.dart';
import 'package:gizmoglobe_client/enums/processing/process_state_enum.dart';
import 'package:gizmoglobe_client/widgets/product/product_card.dart';

class PartsPickerScreen extends StatefulWidget {
  final CategoryEnum category;
  final Function(Product) onProductSelected;

  const PartsPickerScreen({
    super.key,
    required this.category,
    required this.onProductSelected,
  });

  static Widget newInstance({
    required CategoryEnum category,
    required Function(Product) onProductSelected,
  }) =>
      BlocProvider(
        create: (context) => PartsPickerCubit(category),
        child: PartsPickerScreen(
          category: category,
          onProductSelected: onProductSelected,
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
        onProductSelected: widget.onProductSelected,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryLabel(widget.category)),
      ),
      body: BlocBuilder<PartsPickerCubit, PartsPickerState>(
        builder: (context, state) {
          if (state.processState == ProcessState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.products.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return GestureDetector(
                onTap: () => widget.onProductSelected(product),
                child: ProductCard(product: product),
              );
            },
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
}
