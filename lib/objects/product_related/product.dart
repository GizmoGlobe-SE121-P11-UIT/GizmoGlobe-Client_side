import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:gizmoglobe_client/objects/manufacturer.dart';

import '../../enums/product_related/category_enum.dart';
import '../../enums/product_related/product_status_enum.dart';
import 'product_factory.dart';

abstract class Product {
  String? productID;
  String? imageUrl;
  final String productName;
  final CategoryEnum category;
  final double price;
  final double discount;
  DateTime release;
  int stock;
  int sales;
  String? enDescription;
  String? viDescription;
  final Manufacturer manufacturer;
  ProductStatusEnum status;

  double get discountedPrice => price * (1 - discount);

  double get discountPercentage {
    return discount > 0 ? (discount * 100) : 0;
  }

  Product({
    this.productID,
    this.imageUrl,
    required this.productName,
    required this.price,
    required this.manufacturer,
    required this.category,
    required this.discount,
    required this.release,
    required this.sales,
    required this.stock,
    required this.status,
    this.enDescription,
    this.viDescription,
  });

  static Product fromMap(Map<String, dynamic> data) {
    final category =
        CategoryEnum.values.firstWhere((c) => c.getName() == data['category']);

    return ProductFactory.createProduct(category, {
      'productID': data['productID'],
      'imageUrl': data['imageUrl'] as String?,
      'productName': data['productName'],
      'price': (data['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      'discount': (data['discount'] as num?)?.toDouble() ?? 0.0,
      'release': (data['release'] as Timestamp).toDate(),
      'sales': data['sales'] as int,
      'stock': data['stock'] as int,
      'status': ProductStatusEnum.values
          .firstWhere((s) => s.getName() == data['status']),
      'manufacturer': data['manufacturerID'].toString(),
      'enDescription': data['enDescription'] as String?,
      'viDescription': data['viDescription'] as String?,
    });
  }

  Product changeCategory(
      CategoryEnum newCategory, Map<String, dynamic> properties) {
    properties['productID'] = productID;
    return ProductFactory.createProduct(newCategory, properties);
  }

  String? getDescription(BuildContext context) {
    final locale = Localizations.localeOf(context);
    print('Current locale: ${locale.languageCode}');
    if (locale.languageCode == 'vi') {
      print('Returning Vietnamese description: $viDescription');
      return viDescription;
    } else {
      print('Returning English description: $enDescription');
      return enDescription;
    }
  }
}