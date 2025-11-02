import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:intl/intl.dart';

class AICartService {
  final FirebaseFirestore _firestore;

  AICartService(this._firestore);

  /// Add product to cart
  Future<bool> addProductToCart(
      String userId, String productID, int quantity) async {
    try {
      // Check if user document exists
      final userDoc =
          await _firestore.collection('customers').doc(userId).get();
      if (!userDoc.exists) {
        await _firestore.collection('customers').doc(userId).set({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Get product information
      final productDoc =
          await _firestore.collection('products').doc(productID).get();
      if (!productDoc.exists) {
        if (kDebugMode) {
          print('Product not found: $productID');
        }
        return false;
      }

      final productData = productDoc.data()!;
      final price = (productData['sellingPrice'] as num).toDouble();
      final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
      final discountedPrice = price * (1 - discount / 100);

      // Reference to cart item
      final cartRef = _firestore
          .collection('customers')
          .doc(userId)
          .collection('carts')
          .doc(productID);

      // Check if item exists in cart
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        final subtotal = (discountedPrice * quantity).toStringAsFixed(2);
        if (kDebugMode) {
          print('Creating new cart item with subtotal: $subtotal');
        }

        await cartRef.set({
          'quantity': quantity,
          'subtotal': double.parse(subtotal),
          'productID': productID,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final currentQuantity =
            (cartDoc.data()?['quantity'] as num?)?.toInt() ?? 0;
        final newQuantity = currentQuantity + quantity;
        final subtotal = (discountedPrice * newQuantity).toStringAsFixed(2);

        if (kDebugMode) {
          print('Updating existing cart item:');
          print('Current quantity: $currentQuantity');
          print('New quantity: $newQuantity');
          print('New subtotal: $subtotal');
        }

        await cartRef.update({
          'quantity': newQuantity,
          'subtotal': double.parse(subtotal),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding product to cart: $e');
      }
      return false;
    }
  }

  /// Get add to cart success response
  String getAddToCartSuccessResponse(
      Map<String, dynamic> product, int quantity, bool isVietnamese) {
    final productDisplayName = product['productName'] ?? 'Unknown Product';
    final price = product['sellingPrice'] ?? 0.0;
    final discount = product['discount'] ?? 0.0;
    final finalPrice = price * (1 - discount / 100);

    return isVietnamese
        ? '✅ Đã thêm $quantity ${quantity > 1 ? 'sản phẩm' : 'sản phẩm'} "$productDisplayName" vào giỏ hàng thành công!\n\n💰 Giá: ${Helper.toCurrencyFormat(finalPrice)}\n📦 Số lượng: $quantity\n💵 Tổng: ${Helper.toCurrencyFormat(finalPrice * quantity)}\n\nBạn có thể xem giỏ hàng của mình trong ứng dụng.'
        : '✅ Successfully added $quantity ${quantity > 1 ? 'items' : 'item'} of "$productDisplayName" to your cart!\n\n💰 Price: ${Helper.toCurrencyFormat(finalPrice)}\n📦 Quantity: $quantity\n💵 Total: ${Helper.toCurrencyFormat(finalPrice * quantity)}\n\nYou can view your cart in the app.';
  }
}
