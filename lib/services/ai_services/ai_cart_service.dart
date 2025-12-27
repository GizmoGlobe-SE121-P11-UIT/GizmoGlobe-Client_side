import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/functions/helper.dart';

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
    final price = (product['sellingPrice'] ?? 0.0) as num;
    final discount = (product['discount'] ?? 0.0) as num;
    // Discount is stored as percentage (0-100), not multiplier (0-1)
    final finalPrice = price * (1 - discount.toDouble() / 100);

    return isVietnamese
        ? 'Đã thêm $quantity ${quantity > 1 ? 'sản phẩm' : 'sản phẩm'} "$productDisplayName" vào giỏ hàng thành công!\n\nGiá: ${Helper.toCurrencyFormat(finalPrice)}\nSố lượng: $quantity\nTổng: ${Helper.toCurrencyFormat(finalPrice * quantity)}\n\nBạn có thể xem giỏ hàng của mình trong ứng dụng.'
        : 'Successfully added $quantity ${quantity > 1 ? 'items' : 'item'} of "$productDisplayName" to your cart!\n\nPrice: ${Helper.toCurrencyFormat(finalPrice)}\nQuantity: $quantity\nTotal: ${Helper.toCurrencyFormat(finalPrice * quantity)}\n\nYou can view your cart in the app.';
  }

  /// Add product to favorites/wishlist
  Future<bool> addProductToFavorites(String userId, String productID) async {
    try {
      // Check if user document exists
      final userDoc =
          await _firestore.collection('customers').doc(userId).get();
      if (!userDoc.exists) {
        await _firestore.collection('customers').doc(userId).set({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Get product information to verify it exists
      final productDoc =
          await _firestore.collection('products').doc(productID).get();
      if (!productDoc.exists) {
        if (kDebugMode) {
          print('Product not found: $productID');
        }
        return false;
      }

      // Reference to favorites item
      final favoriteRef = _firestore
          .collection('customers')
          .doc(userId)
          .collection('favorites')
          .doc(productID);

      // Check if item already exists in favorites
      final favoriteDoc = await favoriteRef.get();

      if (!favoriteDoc.exists) {
        await favoriteRef.set({
          'productID': productID,
          'addedAt': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        // Already in favorites
        if (kDebugMode) {
          print('Product already in favorites: $productID');
        }
        return true; // Still return true since it's in favorites
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding product to favorites: $e');
      }
      return false;
    }
  }

  /// Get add to favorites success response
  String getAddToFavoritesSuccessResponse(
      Map<String, dynamic> product, bool isVietnamese) {
    final productDisplayName = product['productName'] ?? 'Unknown Product';
    final price = (product['sellingPrice'] ?? 0.0) as num;
    final discount = (product['discount'] ?? 0.0) as num;
    final finalPrice = price * (1 - discount.toDouble() / 100);

    return isVietnamese
        ? 'Đã thêm "$productDisplayName" vào danh sách yêu thích!\n\nGiá: ${Helper.toCurrencyFormat(finalPrice)}\n\nBạn có thể xem danh sách yêu thích trong ứng dụng.'
        : 'Successfully added "$productDisplayName" to your favorites!\n\nPrice: ${Helper.toCurrencyFormat(finalPrice)}\n\nYou can view your favorites in the app.';
  }
}
