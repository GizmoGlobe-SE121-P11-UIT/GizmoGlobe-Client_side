import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/database/database.dart';
import 'package:gizmoglobe_client/objects/product_related/cpu.dart';
import 'package:gizmoglobe_client/objects/product_related/drive.dart';
import 'package:gizmoglobe_client/objects/product_related/gpu.dart';
import 'package:gizmoglobe_client/objects/product_related/mainboard.dart';
import 'package:gizmoglobe_client/objects/product_related/psu.dart';
import 'package:gizmoglobe_client/objects/product_related/ram.dart';

import '../../objects/address_related/address.dart';

Future<void> pushProductSamplesToFirebase() async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Database().generateSampleData();
    for (var manufacturer in Database().manufacturerList) {
      await firestore.collection('manufacturers').doc(manufacturer.manufacturerID).set({
        'manufacturerID': manufacturer.manufacturerID,
        'manufacturerName': manufacturer.manufacturerName,
      });
    }

    // Push products to Firestore
    for (var product in Database().productList) {
      Map<String, dynamic> productData = {
        'productName': product.productName,
        'price': product.price,
        'manufacturerID': product.manufacturer.manufacturerID,
        'category': product.category.getName(),
      };

      // Thêm các thuộc tính đặc thù cho từng loại sản phẩm
      switch (product.runtimeType) {
        case RAM:
          final ram = product as RAM;
          productData.addAll({
            'bus': ram.bus.getName(),
            'capacity': ram.capacity.getName(),
            'ramType': ram.ramType.getName(),
          });
          break;

        case CPU:
          final cpu = product as CPU;
          productData.addAll({
            'family': cpu.family.getName(),
            'core': cpu.core,
            'thread': cpu.thread,
            'clockSpeed': cpu.clockSpeed,
          });
          break;

        case GPU:
          final gpu = product as GPU;
          productData.addAll({
            'series': gpu.series.getName(),
            'capacity': gpu.capacity.getName(),
            'busWidth': gpu.bus.getName(),
            'clockSpeed': gpu.clockSpeed,
          });
          break;

        case Mainboard:
          final mainboard = product as Mainboard;
          productData.addAll({
            'formFactor': mainboard.formFactor.getName(),
            'series': mainboard.series.getName(),
            'compatibility': mainboard.compatibility.getName(),
          });
          break;

        case Drive:
          final drive = product as Drive;
          productData.addAll({
            'type': drive.type.getName(),
            'capacity': drive.capacity.getName(),
          });
          break;

        case PSU:
          final psu = product as PSU;
          productData.addAll({
            'wattage': psu.wattage,
            'efficiency': psu.efficiency.getName(),
            'modular': psu.modular.getName(),
          });
          break;
      }

      // Thêm sản phẩm vào Firestore với tất cả thuộc tính
      await firestore.collection('products').add(productData);
    }
  } catch (e) {
    print('Error pushing product samples to Firebase: $e');
  }
}

class Firebase {
  static final Firebase _firebase = Firebase._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thêm các constant cho retry
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  // Hàm helper để retry operation
  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) {
          print('Final attempt failed: $e');
          rethrow;
        }
        print('Attempt $attempts failed, retrying in ${retryDelayMs}ms...');
        await Future.delayed(Duration(milliseconds: retryDelayMs * attempts));
      }
    }
    throw Exception('Retry operation failed after $maxRetries attempts');
  }

  factory Firebase() {
    return _firebase;
  }

  Firebase._internal();

  // Thêm getter để truy cập Firestore instance
  FirebaseFirestore get firestore => _firestore;

  // Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(String customerID, String productID, int quantity) async {
    await _retryOperation(() async {
      try {
        print('Adding to cart - UserID: $customerID, ProductID: $productID, Quantity: $quantity');

        // Check if user document exists
        final userDoc = await _firestore.collection('customers').doc(customerID).get();
        if (!userDoc.exists) {
          await _firestore.collection('customers').doc(customerID).set({
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Get product information
        final productDoc = await _firestore.collection('products').doc(productID).get();
        if (!productDoc.exists) {
          print('Product not found: $productID');
          throw Exception('Product not found');
        }

        final productData = productDoc.data()!;
        final price = (productData['sellingPrice'] as num).toDouble();
        final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
        final discountedPrice = price * (1 - discount / 100);

        // Reference to cart item
        final cartRef = _firestore
            .collection('customers')
            .doc(customerID)
            .collection('carts')
            .doc(productID);

        // Check if item exists in cart
        final cartDoc = await cartRef.get();
        print('Cart document exists: ${cartDoc.exists}');

        if (!cartDoc.exists) {
          final subtotal = (discountedPrice * quantity).toStringAsFixed(2);
          print('Creating new cart item with subtotal: $subtotal');

          await cartRef.set({
            'quantity': quantity,
            'subtotal': double.parse(subtotal),
            'productID': productID, // Add reference to product
            'addedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final currentQuantity = (cartDoc.data()?['quantity'] as num?)?.toInt() ?? 0;
          final newQuantity = currentQuantity + quantity;
          final subtotal = (discountedPrice * newQuantity).toStringAsFixed(2);

          print('Updating existing cart item:');
          print('Current quantity: $currentQuantity');
          print('New quantity: $newQuantity');
          print('New subtotal: $subtotal');

          await cartRef.update({
            'quantity': newQuantity,
            'subtotal': double.parse(subtotal),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Verify the operation
        final verifyDoc = await cartRef.get();
        print('Verification - Cart item data:');
        print(verifyDoc.data());

      } catch (e) {
        print('Error in addToCart operation: $e');
        rethrow;
      }
    });
  }
  // Cập nhật số lượng sản phẩm trong giỏ hàng
  Future<void> updateCartItemQuantity(String customerID, String productID, int newQuantity) async {
    await _retryOperation(() async {
      try {
        print('Updating quantity - UserID: $customerID, ProductID: $productID, New Quantity: $newQuantity');

        if (newQuantity <= 0) {
          await removeFromCart(customerID, productID);
          return;
        }

        final productDoc = await _firestore.collection('products').doc(productID).get();
        if (!productDoc.exists) {
          print('Product not found: $productID');
          throw Exception('Product not found');
        }

        final productData = productDoc.data()!;
        final price = (productData['sellingPrice'] as num).toDouble();
        final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
        final discountedPrice = price * (1 - discount / 100);
        final subtotal = (discountedPrice * newQuantity).toStringAsFixed(2);

        final cartRef = _firestore
            .collection('customers')
            .doc(customerID)
            .collection('carts')
            .doc(productID);

        print('Updating cart with:');
        print('New quantity: $newQuantity');
        print('New subtotal: $subtotal');

        await cartRef.update({
          'quantity': newQuantity,
          'subtotal': double.parse(subtotal),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Verify the update
        final verifyDoc = await cartRef.get();
        print('Verification - Updated cart item:');
        print(verifyDoc.data());

      } catch (e) {
        print('Error in updateCartItemQuantity: $e');
        rethrow;
      }
    });
  }
  // Xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(String customerID, String productID) async {
    try {
      await _firestore
          .collection('customers')
          .doc(customerID)
          .collection('carts')
          .doc(productID)
          .delete();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  // Lấy tất cả sản phẩm trong giỏ hàng của user
  Future<List<Map<String, dynamic>>> getCartItems(String customerID) async {
    return await _retryOperation(() async {
      try {
        final cartSnapshot = await _firestore
            .collection('customers')
            .doc(customerID)
            .collection('carts')
            .get();

        final List<Map<String, dynamic>> items = [];

        for (var doc in cartSnapshot.docs) {
          final productID = doc.id;
          final cartData = doc.data();

          // Lấy thông tin sản phẩm
          final productDoc = await _firestore
              .collection('products')
              .doc(productID)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            final quantity = cartData['quantity'] as int;

            // Tính lại subtotal
            final price = (productData['sellingPrice'] as num).toDouble();
            final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
            final discountedPrice = price * (1 - discount / 100);
            final subtotal = discountedPrice * quantity;

            items.add({
              'productID': productID,
              'quantity': quantity,
              'subtotal': subtotal,
              'product': productData,
            });
          }
        }

        return items;
      } catch (e) {
        print('Error in getCartItems operation: $e');
        rethrow;
      }
    });
  }

  // Xóa toàn bộ giỏ hàng của user
  Future<void> clearCart(String customerID) async {
    try {
      final cartRef = _firestore
          .collection('customers')
          .doc(customerID)
          .collection('carts');

      final cartDocs = await cartRef.get();

      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  Future<void> createAddress(Address address) async {
    try {
      // Add address to collection addresses
      DocumentReference addressRef = await FirebaseFirestore.instance
          .collection('addresses')
          .add(address.toMap());

      String addressId = addressRef.id;
      address.addressID = addressId;

      await addressRef.update({'addressID': addressId});
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(addressId)
          .set({
        'addressID': addressId,
        'customerID': address.customerID,
        'receiverName': address.receiverName,
        'receiverPhone': address.receiverPhone,
        'provinceCode': address.province?.code,
        'districtCode': address.district?.code,
        'wardCode': address.ward?.code,
        'street': address.street ?? '',
      });

      await Database().fetchAddress();
    } catch (e) {
      print('Error creating new address: $e');
      rethrow;
    }
  }
}