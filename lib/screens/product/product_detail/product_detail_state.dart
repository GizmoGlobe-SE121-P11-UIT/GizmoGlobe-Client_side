import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';


class ProductDetailState extends Equatable {
  final Product product;
  final int quantity;
  final Map<String, String> technicalSpecs;

  const ProductDetailState({
    required this.product,
    this.quantity = 1,
    this.technicalSpecs = const {},
  });

  @override
  List<Object?> get props => [product, technicalSpecs, quantity];

  ProductDetailState copyWith({
    Product? product,
    Map<String, String>? technicalSpecs,
    int? quantity,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      quantity: quantity ?? this.quantity,
    );
  }
}