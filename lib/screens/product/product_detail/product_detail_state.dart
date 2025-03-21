import 'package:equatable/equatable.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';


class ProductDetailState extends Equatable {
  final Product product;
  final Map<String, String> technicalSpecs;

  const ProductDetailState({
    required this.product,
    this.technicalSpecs = const {},
  });

  @override
  List<Object?> get props => [product, technicalSpecs];

  ProductDetailState copyWith({
    Product? product,
    Map<String, String>? technicalSpecs,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
    );
  }
}