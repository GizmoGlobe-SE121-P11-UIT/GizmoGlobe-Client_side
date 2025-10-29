import 'package:gizmoglobe_client/objects/product_related/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  double subTotal() {
    return product.discountedPrice * quantity;
  }

  int subTotalBeforeDiscount() {
    return product.price * quantity;
  }

  CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}