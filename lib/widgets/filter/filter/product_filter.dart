import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';

import '../../../data/database/database.dart';
import '../option_filter/option_filter_view.dart';
import '../range_filter/range_filter_view.dart';

class ProductFilterScreen extends StatelessWidget {
  const ProductFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Filter', style: AppTextStyle.bigText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptionFilterView<CategoryEnum>(
              name: 'Category',
              enumValues: CategoryEnum.values,
              onSelected: (category) {
                // Handle category selection
              },
            ),
            const SizedBox(height: 16.0),
            OptionFilterView<Manufacturer>(
              name: 'Manufacturer',
              enumValues: Database().manufacturerList,
              onSelected: (manufacturer) {
                // Handle manufacturer selection
              },
            ),
            const SizedBox(height: 16.0),
            RangeFilterView(name: 'Price'),
          ],
        ),
      ),
    );
  }
}