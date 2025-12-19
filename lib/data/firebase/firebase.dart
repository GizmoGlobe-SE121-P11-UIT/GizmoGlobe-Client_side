import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/database.dart';

import '../../enums/invoice_related/sales_status.dart';
import '../../enums/manufacturer/manufacturer_status.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../enums/voucher_related/voucher_display_type.dart';
import '../../objects/address_related/address.dart';
import '../../objects/invoice_related/rating.dart';
import '../../objects/invoice_related/ratings_page.dart';
import '../../objects/invoice_related/sales_invoice.dart';
import '../../objects/invoice_related/sales_invoice_detail.dart';
import '../../objects/manufacturer.dart';
import '../../objects/product_related/product_image.dart';
import '../../objects/voucher_related/owned_voucher.dart';
import '../../objects/voucher_related/voucher.dart';
import '../../objects/voucher_related/voucher_factory.dart';

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
          if (kDebugMode) {
            print('Final attempt failed: $e');
          }
          rethrow;
        }
        if (kDebugMode) {
          print('Attempt $attempts failed, retrying in ${retryDelayMs}ms...');
        }
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
  Future<void> addToCart(
      String customerID, String productID, int quantity) async {
    await _retryOperation(() async {
      try {
        if (kDebugMode) {
          print(
              'Adding to cart - UserID: $customerID, ProductID: $productID, Quantity: $quantity');
        }
        // Check if user document exists
        final userDoc =
            await _firestore.collection('customers').doc(customerID).get();
        if (!userDoc.exists) {
          await _firestore.collection('customers').doc(customerID).set({
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

        if (!cartDoc.exists) {
          final subtotal = (discountedPrice * quantity).toStringAsFixed(2);

          await cartRef.set({
            'quantity': quantity,
            'subtotal': double.parse(subtotal),
            'productID': productID, // Add reference to product
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
      } catch (e) {
        if (kDebugMode) {
          print('Error in addToCart operation: $e');
        }
        rethrow;
      }
    });
  }

  // Cập nhật số lượng sản phẩm trong giỏ hàng
  Future<void> updateCartItemQuantity(
      String customerID, String productID, int newQuantity) async {
    await _retryOperation(() async {
      try {
        if (newQuantity <= 0) {
          await removeFromCart(customerID, productID);
          return;
        }

        final productDoc =
            await _firestore.collection('products').doc(productID).get();
        if (!productDoc.exists) {
          if (kDebugMode) {
            print('Product not found: $productID');
          }
          throw Exception('Product not found');
        }

        final productData = productDoc.data()!;
        final price = (productData['sellingPrice'] as num).toDouble();
        final discount = (productData['discount'] as num?)?.toDouble() ?? 0.0;
        final discountedPrice = price * (1 - discount / 100);
        (discountedPrice * newQuantity).toStringAsFixed(2);

        final cartRef = _firestore
            .collection('customers')
            .doc(customerID)
            .collection('carts')
            .doc(productID);
        // Update the cart item
        await cartRef.update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error in updateCartItemQuantity: $e');
        }
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
      if (kDebugMode) {
        print('Error removing from cart: $e');
      }
      rethrow;
    }
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
      if (kDebugMode) {
        print('Error clearing cart: $e');
      }
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
        'hidden': false,
      });

      await Database().fetchAddress();
    } catch (e) {
      if (kDebugMode) {
        print('Error creating new address: $e');
      }
      rethrow;
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(address.addressID)
          .update(address.toMap());

      await Database().fetchAddress();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating address: $e');
      }
      rethrow;
    }
  }

  Future<void> addFavorite(String customerID, String productID) async {
    try {
      final favoriteRef = _firestore
          .collection('customers')
          .doc(customerID)
          .collection('favorites')
          .doc(productID);

      await favoriteRef.set({
        'productID': productID,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding favorite: $e');
      }
      rethrow;
    }
  }

  Future<void> removeFavorite(String customerID, String productID) async {
    try {
      final favoriteRef = _firestore
          .collection('customers')
          .doc(customerID)
          .collection('favorites')
          .doc(productID);

      await favoriteRef.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing favorite: $e');
      }
      rethrow;
    }
  }

  Future<List<String>> getFavorites(String customerID) async {
    try {
      final favoriteSnapshot = await _firestore
          .collection('customers')
          .doc(customerID)
          .collection('favorites')
          .get();

      return favoriteSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorites: $e');
      }
      rethrow;
    }
  }

  Future<Manufacturer?> getManufacturerById(String manufacturerId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('manufacturers')
          .where('manufacturerID', isEqualTo: manufacturerId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final data = querySnapshot.docs.first.data();
      final docStatus = data['status'] as String?;
      return Manufacturer(
        manufacturerID: data['manufacturerID'] ?? '',
        manufacturerName: data['manufacturerName'] ?? '',
        status: ManufacturerStatus.values.firstWhere(
          (e) =>
              e.getName().toLowerCase() ==
              (docStatus?.toLowerCase() ??
                  ManufacturerStatus.active.getName().toLowerCase()),
          orElse: () => ManufacturerStatus.active,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error finding manufacturer by ID: $e');
      }
      rethrow;
    }
  }

  Future<void> changeProductStatus(
      String productId, ProductStatusEnum status) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({'status': status.getName()});

      await Database().getProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error changing product status: $e');
      }
      rethrow;
    }
  }

  Future<void> addSalesInvoice(SalesInvoice salesInvoice) async {
    try {
      final salesInvoiceRef = await _firestore
          .collection('sales_invoices')
          .add(salesInvoice.toMap());

      String salesInvoiceID = salesInvoiceRef.id;
      salesInvoice.salesInvoiceID = salesInvoiceID;

      await salesInvoiceRef.update({'salesInvoiceID': salesInvoiceID});
      final invoiceData = {
        ...salesInvoice.toMap(),
        'salesInvoiceID': salesInvoiceID,
        // Store only the address ID to keep payload small/normalized
        'address': salesInvoice.address?.addressID ?? '',
      };

      await _firestore
          .collection('sales_invoices')
          .doc(salesInvoiceID)
          .set(invoiceData);

      for (SalesInvoiceDetail detail in salesInvoice.details) {
        await _firestore
            .collection('sales_invoice_details')
            .add(detail.toMap(salesInvoiceID));
      }

      // Decrement product stock when invoice is created
      await _decrementProductStock(salesInvoice.details);

      // Update voucher usage if a voucher was applied
      if (salesInvoice.voucher != null) {
        await _updateVoucherUses(
            salesInvoice.customerID, salesInvoice.voucher!);
      }

      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding sales invoice: $e');
      }
      rethrow;
    }
  }

  /// Update an existing sales invoice in Firebase
  Future<void> updateSalesInvoice(SalesInvoice salesInvoice) async {
    try {
      if (salesInvoice.salesInvoiceID == null ||
          salesInvoice.salesInvoiceID!.isEmpty) {
        throw Exception('Cannot update invoice: No invoice ID');
      }

      final invoiceRef = _firestore
          .collection('sales_invoices')
          .doc(salesInvoice.salesInvoiceID);

      // Update the main invoice document
      final updatedInvoiceData = {
        ...salesInvoice.toMap(),
        // Ensure ID stays in sync
        'salesInvoiceID': salesInvoice.salesInvoiceID,
        // Store only the address ID to keep payload small/normalized
        'address': salesInvoice.address?.addressID ?? '',
      };

      await invoiceRef.update(updatedInvoiceData);

      // Delete existing invoice details
      final existingDetailsSnapshot = await _firestore
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: salesInvoice.salesInvoiceID)
          .get();

      for (var doc in existingDetailsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Add updated invoice details
      for (SalesInvoiceDetail detail in salesInvoice.details) {
        await _firestore
            .collection('sales_invoice_details')
            .add(detail.toMap(salesInvoice.salesInvoiceID!));
      }

      // Update voucher usage if a voucher was applied
      if (salesInvoice.voucher != null) {
        await _updateVoucherUses(
            salesInvoice.customerID, salesInvoice.voucher!);
      }

      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating sales invoice: $e');
      }
      rethrow;
    }
  }

  Future<List<SalesInvoice>> getSalesInvoices() async {
    try {
      String userId = Database().userID;
      if (userId.isEmpty) {
        return [];
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .where('customerID', isEqualTo: userId)
          .get();

      return await Future.wait(snapshot.docs.map((doc) async {
        SalesInvoice salesInvoice =
            SalesInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);

        final QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
            .collection('sales_invoice_details')
            .where('salesInvoiceID', isEqualTo: salesInvoice.salesInvoiceID)
            .get();

        salesInvoice.details = detailsSnapshot.docs.map((detailDoc) {
          final detailData = detailDoc.data() as Map<String, dynamic>;
          final productID = detailData['productID'] as String?;

          if (productID == null || productID.isEmpty) {
            throw Exception('Product ID is missing in sales invoice detail');
          }

          final product = Database().fullProductList.firstWhere(
            (product) => product.productID == productID,
            orElse: () {
              return Database().productList.firstWhere(
                    (product) => product.productID == productID,
                    orElse: () => throw Exception(
                        'Product not found in any product list: $productID'),
                  );
            },
          );

          return SalesInvoiceDetail(
            salesInvoiceDetailID: detailDoc.id,
            salesInvoiceID: salesInvoice.salesInvoiceID,
            product: product,
            quantity: detailData['quantity'] as int,
            sellingPrice: (detailData['sellingPrice'] as num).toInt(),
            subtotal: (detailData['subtotal'] as num).toInt(),
          );
        }).toList();

        return salesInvoice;
      }).toList());
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sales invoices: $e');
      }
      rethrow;
    }
  }

  Future<void> updateLoyalPoint(String userID, int point) async {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userID)
          .update({'loyalPoint': point});
  }

  Future<SalesInvoice?> getSalesInvoiceById(String salesInvoiceID) async {
    try {
      final userID = Database().userID;
      // Check if userID is empty or null (e.g., for guest users)
      if (userID.isEmpty) {
        return null;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .doc(salesInvoiceID)
          .get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print('Sales invoice not found: $salesInvoiceID');
        }
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Verify that the invoice belongs to the current user
      if (data['customerID'] != userID) {
        return null;
      }

      SalesInvoice salesInvoice = SalesInvoice.fromMap(docSnapshot.id, data);

      final QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: salesInvoiceID)
          .get();

      salesInvoice.details = detailsSnapshot.docs.map((detailDoc) {
        final detailData = detailDoc.data() as Map<String, dynamic>;
        final productID = detailData['productID'] as String?;

        if (productID == null || productID.isEmpty) {
          throw Exception('Product ID is missing in sales invoice detail');
        }

        // Try to find product in fullProductList first, then productList
        final product = Database().fullProductList.firstWhere(
          (product) => product.productID == productID,
          orElse: () {
            return Database().productList.firstWhere(
                  (product) => product.productID == productID,
                  orElse: () => throw Exception(
                      'Product not found in any product list: $productID'),
                );
          },
        );

        return SalesInvoiceDetail(
          salesInvoiceDetailID: detailDoc.id,
          salesInvoiceID: salesInvoice.salesInvoiceID,
          product: product,
          quantity: detailData['quantity'] as int,
          sellingPrice: (detailData['sellingPrice'] as num).toInt(),
          subtotal: (detailData['subtotal'] as num).toInt(),
        );
      }).toList();

      // Load voucher if voucherID exists
      final voucherID = data['voucherID'] as String?;
      if (voucherID != null && voucherID.isNotEmpty) {
        try {
          final voucher = Database().allVoucherList.firstWhere(
                (v) => v.voucherID == voucherID,
                orElse: () => throw Exception('Voucher not found: $voucherID'),
              );
          // Note: SalesInvoice.fromMap doesn't load voucher, so we need to update it
          // We'll need to create a new invoice with the voucher
          return SalesInvoice(
            salesInvoiceID: salesInvoice.salesInvoiceID,
            customerID: salesInvoice.customerID,
            customerName: salesInvoice.customerName,
            address: salesInvoice.address,
            date: salesInvoice.date,
            salesStatus: salesInvoice.salesStatus,
            totalPrice: salesInvoice.totalPrice,
            paymentStatus: salesInvoice.paymentStatus,
            details: salesInvoice.details,
            voucher: voucher,
            voucherDiscount:
                (data['voucherDiscount'] as num?)?.toDouble() ?? 0.0,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Could not load voucher: $e');
          }
          // Continue without voucher if not found
        }
      }

      return salesInvoice;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sales invoice by ID: $e');
      }
      rethrow;
    }
  }

  Future<List<Rating>> getRatingsByUser(String userID) async {
    try {
      final uid = Database().userID;
      if (uid.isEmpty) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('order_ratings')
          .where('userID', isEqualTo: uid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Rating.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting ratings by user: $e');
      }
      rethrow;
    }
  }

  Future<void> submitOrderRating({
    required String userID,
    required String productId,
    required int rating,
    String? comment,
    List<File>? images,
    File? video,
    String? invoiceId,
  }) async {
    await _retryOperation(() async {
      try {
        if (userID.isEmpty || productId.isEmpty) {
          throw Exception('userID and productId are required');
        }

        final docRef = await _firestore.collection('order_ratings').add({
          'userID': userID,
          'productID': productId,
          'timeSent': FieldValue.serverTimestamp(),
          'rating': rating,
          'comment': comment,
          'imagesUrl': null,
          'videoUrl': null,
        });

        final docId = docRef.id;
        List<String>? uploadedImageUrls;
        String? uploadedVideoUrl;

        if (images != null && images.isNotEmpty) {
          uploadedImageUrls = [];
          for (var i = 0; i < images.length; i++) {
            final file = images[i];
            final ext = file.path.split('.').last;
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('ratings')
                .child(docId)
                .child('images')
                .child(
                    'img_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext');

            final uploadTask = storageRef.putFile(file);
            await uploadTask.whenComplete(() => null);
            final url = await storageRef.getDownloadURL();
            uploadedImageUrls.add(url);
          }
        }

        if (video != null) {
          final ext = video.path.split('.').last;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('ratings')
              .child(docId)
              .child('video')
              .child('video_${DateTime.now().millisecondsSinceEpoch}.$ext');

          final uploadTask = storageRef.putFile(video);
          await uploadTask.whenComplete(() => null);
          uploadedVideoUrl = await storageRef.getDownloadURL();
        }

        await docRef.update({
          'imagesUrl': uploadedImageUrls,
          'videoUrl': uploadedVideoUrl,
        });

        // If invoiceId is provided, check whether all products in that invoice are rated by this user.
        if (invoiceId != null && invoiceId.isNotEmpty) {
          await _markInvoiceCompletedIfAllRated(invoiceId, userID);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error submitting order rating: $e');
        }
        rethrow;
      }
    });
  }

  Future<void> _markInvoiceCompletedIfAllRated(
      String invoiceId, String userId) async {
    try {
      final detailsSnapshot = await _firestore
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: invoiceId)
          .get();

      final productIds = detailsSnapshot.docs
          .map((d) {
            final map = d.data();
            return (map['productID'] as String?) ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toList();

      if (productIds.isEmpty) return;

      for (final pid in productIds) {
        final ratingSnap = await _firestore
            .collection('order_ratings')
            .where('userID', isEqualTo: userId)
            .where('productID', isEqualTo: pid)
            .limit(1)
            .get();

        if (ratingSnap.docs.isEmpty) {
          // found an unrated product -> stop
          return;
        }
      }

      // All products have a rating by this user; mark invoice as completed.
      await _firestore.collection('sales_invoices').doc(invoiceId).update({
        'salesStatus': SalesStatus.completed.getName(),
      });

      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking/completing invoice after rating: $e');
      }
      // non-critical; do not rethrow
    }
  }

  Future<void> confirmDelivery(SalesInvoice salesInvoice) async {
    try {
      await _firestore
          .collection('sales_invoices')
          .doc(salesInvoice.salesInvoiceID)
          .update({
        'salesStatus': SalesStatus.received.getName(),
      });
      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming delivery: $e');
      }
      rethrow;
    }
  }

  /// Restores product stock when invoice is cancelled
  Future<void> cancelSalesInvoice(String salesInvoiceID,
      {bool revertVoucherUsage = true}) async {
    try {
      // Get the invoice to check if it has a voucher and get details
      final invoiceDoc = await _firestore
          .collection('sales_invoices')
          .doc(salesInvoiceID)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Invoice not found: $salesInvoiceID');
      }

      final invoiceData = invoiceDoc.data() as Map<String, dynamic>;
      final voucherID = invoiceData['voucherID'] as String?;

      // Get invoice details to restore stock
      final detailsSnapshot = await _firestore
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: salesInvoiceID)
          .get();

      // Restore product stock when invoice is cancelled
      if (detailsSnapshot.docs.isNotEmpty) {
        try {
          final details = detailsSnapshot.docs.map((doc) {
            final data = doc.data();
            final productID = data['productID'] as String?;
            final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
            return {'productID': productID, 'quantity': quantity};
          }).where((d) {
            final productID = d['productID'] as String?;
            return productID != null && productID.isNotEmpty;
          }).toList();

          await _restoreProductStock(details);
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Could not restore product stock: $e');
          }
          // Continue with cancellation even if stock restore fails
        }
      }

      if (revertVoucherUsage && voucherID != null && voucherID.isNotEmpty) {
        try {
          final voucher = Database().allVoucherList.firstWhere(
                (v) => v.voucherID == voucherID,
                orElse: () => throw Exception('Voucher not found: $voucherID'),
              );
          final customerID = invoiceData['customerID'] as String;
          await _revertVoucherUses(customerID, voucher);
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Could not revert voucher usage: $e');
          }
        }
      }

      // Mark invoice as cancelled
      await _firestore.collection('sales_invoices').doc(salesInvoiceID).update({
        'salesStatus': SalesStatus.cancelled.getName(),
      });
      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling sales invoice: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteSalesInvoice(String salesInvoiceID) async {
    try {
      // Delete all invoice details first
      final detailsSnapshot = await _firestore
          .collection('sales_invoice_details')
          .where('salesInvoiceID', isEqualTo: salesInvoiceID)
          .get();

      for (var doc in detailsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the invoice
      await _firestore
          .collection('sales_invoices')
          .doc(salesInvoiceID)
          .delete();

      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting sales invoice: $e');
      }
      rethrow;
    }
  }

  Future<List<Voucher>> getVouchers() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('vouchers').get();
      final List<Voucher> vouchers = [];

      for (final doc in snapshot.docs) {
        final raw = Map<String, dynamic>.from(doc.data() as Map);
        try {
          final Map<String, dynamic> data = {};

          // id
          data['voucherID'] = doc.id;

          // Strings with safe defaults
          data['voucherName'] = (raw['voucherName']?.toString()) ?? '';
          data['enDescription'] = (raw['enDescription']?.toString()) ?? '';
          data['viDescription'] = (raw['viDescription']?.toString()) ?? '';

          // Booleans with defaults
          data['isEnabled'] = raw['isEnabled'] == null ? true : (raw['isEnabled'] == true);
          data['isPercentage'] = raw['isPercentage'] == true;
          data['hasEndTime'] = raw['hasEndTime'] == true;
          data['isLimited'] = raw['isLimited'] == true;

          // Dates: handle Timestamp, String, DateTime, or absent
          dynamic start = raw['startTime'];
          if (start is Timestamp) {
            start = start.toDate();
          } else if (start is String) {
            try {
              start = DateTime.parse(start);
            } catch (_) {
              start = DateTime.now();
            }
          } else if (start is! DateTime) { 
            start = DateTime.now();
          }
          data['startTime'] = start;

          if (data['hasEndTime'] == true) {
            dynamic end = raw['endTime'];
            if (end is Timestamp) {
              end = end.toDate();
            } else if (end is String) {
              try {
                end = DateTime.parse(end);
              } catch (_) {
                end = DateTime.now().add(const Duration(days: 30));
              }
            } else if (end is! DateTime) {
              end = DateTime.now().add(const Duration(days: 30));
            }
            data['endTime'] = end;
          }

          // Display type: accept string or enum, always pass a string to factory
          final disp = raw['displayType'];
          if (disp is String) {
            data['displayType'] = disp;
          } else if (disp is VoucherDisplayType) {
            data['displayType'] = disp.getName();
          } else {
            data['displayType'] = VoucherDisplayType.adminOnly.getName();
          }

          // Numeric values: coerce safely
          double parseDouble(dynamic v, [double def = 0.0]) {
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? def;
            return def;
          }

          int parseInt(dynamic v, [int def = 0]) {
            if (v is num) return v.toInt();
            if (v is String) return int.tryParse(v) ?? def;
            return def;
          }

          data['discountValue'] = parseDouble(raw['discountValue'], 0.0);
          data['minimumPurchase'] = parseInt(raw['minimumPurchase'], 0);
          data['maxUsagePerPerson'] = parseInt(raw['maxUsagePerPerson'], 1);
          data['redeemPrice'] = parseInt(raw['redeemPrice'], 0);

          if (data['isLimited'] == true) {
            data['maximumUsage'] = parseInt(raw['maximumUsage'], 0);
            data['usageLeft'] = parseInt(raw['usageLeft'], 0);
          }

          if (data['isPercentage'] == true) {
            data['maximumDiscountValue'] = parseDouble(raw['maximumDiscountValue'], 0.0);
          } else {
            data['maximumDiscountValue'] = 0.0;
          }

          // Finally try to build voucher
          final voucher = VoucherFactory.fromMap(doc.id, data);
          vouchers.add(voucher);
        } catch (e, st) {
          if (kDebugMode) {
            print('Warning: skipping voucher ${doc.id} due to parse error: $e');
            print('Document raw data: $raw');
            print(st);
          }
          // skip this doc and continue
        }
      }

      return vouchers;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vouchers: $e');
      }
      rethrow;
    }
  }

  Future<void> addOwnedVoucher(OwnedVoucher ownedVoucher) async {
    try {
      final collectionRef = _firestore.collection('owned_vouchers');
      final docRef = await collectionRef.add(ownedVoucher.toMap());
      await docRef.update({'ownedVoucherID': docRef.id});
    } catch (e) {
      if (kDebugMode) {
        print('Error adding owned voucher: $e');
      }
      rethrow;
    }
  }

  Future<void> removeOwnedVoucher(String ownedVoucherID) async {
    try {
      await FirebaseFirestore.instance
          .collection('owned_vouchers')
          .doc(ownedVoucherID)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing owned voucher: $e');
      }
      rethrow;
    }
  }

  Future<OwnedVoucher> redeemVoucher(String customerID, Voucher voucher) async {
    return await _retryOperation(() async {
      if (customerID.isEmpty) {
        throw Exception('Customer ID is required to redeem voucher');
      }

      if (voucher.isLimited) {
        final voucherRef = _firestore.collection('vouchers').doc(voucher.voucherID);
        await _firestore.runTransaction((tx) async {
          final snap = await tx.get(voucherRef);
          if (!snap.exists) {
            throw Exception('Voucher not found: ${voucher.voucherID}');
          }
          final currentLeft = (snap.data()?['usageLeft'] as num?)?.toInt() ?? 0;
          if (currentLeft <= 0) {
            throw Exception('Voucher has no remaining uses');
          }
          tx.update(voucherRef, {'usageLeft': currentLeft - 1});
        });
      }

      final ownedCollection = _firestore.collection('owned_vouchers');
      final existingQuery = await ownedCollection
          .where('customerID', isEqualTo: customerID)
          .where('voucherID', isEqualTo: voucher.voucherID)
          .limit(1)
          .get();

      OwnedVoucher ownedVoucher;
      if (existingQuery.docs.isEmpty) {
        // create new owned voucher
        final docRef = ownedCollection.doc();
        final data = {
          'customerID': customerID,
          'voucherID': voucher.voucherID,
          'numberOfUses': 1,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(data);
        await docRef.update({'ownedVoucherID': docRef.id});
        ownedVoucher = OwnedVoucher(
          ownedVoucherID: docRef.id,
          voucherID: voucher.voucherID!,
          customerID: customerID,
          numberOfUses: 1,
        );
      } else {
        // increment existing owned voucher uses
        final doc = existingQuery.docs.first;
        final currentUses = (doc.data()['numberOfUses'] as num?)?.toInt() ?? 0;
        await doc.reference.update({'numberOfUses': currentUses + 1});
        final updated = await doc.reference.get();
        final newUses = (updated.data()?['numberOfUses'] as num?)?.toInt() ?? (currentUses + 1);
        ownedVoucher = OwnedVoucher(
          ownedVoucherID: updated.id,
          voucherID: voucher.voucherID!,
          customerID: customerID,
          numberOfUses: newUses,
        );
      }

      // 3) Refresh local lists so cubits / UI can pick up changes
      await Database().updateVoucherLists();

      return ownedVoucher;
    });
  }

  Future<List<OwnedVoucher>> getOwnedVouchersByCustomerId(
      String customerId) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('owned_vouchers')
          .where('customerID', isEqualTo: customerId)
          .get();

      return snapshot.docs
          .map((doc) => OwnedVoucher(
                ownedVoucherID: doc.id,
                voucherID: doc['voucherID'] as String,
                customerID: doc['customerID'] as String,
                numberOfUses: doc['numberOfUses'] as int,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting owned vouchers: $e');
      }
      return [];
    }
  }

  /// Revert voucher usage (increase usage count by 1)
  /// Used when an invoice with a voucher is cancelled
  Future<void> _revertVoucherUses(String customerId, Voucher voucher) async {
    try {
      final ownedVoucherQuery = await _firestore
          .collection('owned_vouchers')
          .where('customerID', isEqualTo: customerId)
          .where('voucherID', isEqualTo: voucher.voucherID)
          .limit(1)
          .get();

      if (ownedVoucherQuery.docs.isNotEmpty) {
        final ownedVoucherDoc = ownedVoucherQuery.docs.first;
        final currentUsage = ownedVoucherDoc.data()['numberOfUses'] as int;
        await ownedVoucherDoc.reference
            .update({'numberOfUses': currentUsage + 1});
      }
      if (voucher.isLimited) {
        final voucherDoc = await _firestore
            .collection('vouchers')
            .doc(voucher.voucherID)
            .get();

        if (voucherDoc.exists) {
          final currentUsageLeft = voucherDoc.data()?['usageLeft'] as int? ?? 0;
          await voucherDoc.reference
              .update({'usageLeft': currentUsageLeft + 1});
        }
      }

      // Update local voucher lists to reflect changes
      await Database().updateVoucherLists();
    } catch (e) {
      if (kDebugMode) {
        print('Error reverting voucher usage: $e');
      }
      rethrow;
    }
  }

  Future<void> _updateVoucherUses(String customerId, Voucher voucher) async {
    try {
      final ownedVoucherQuery = await _firestore
          .collection('owned_vouchers')
          .where('customerID', isEqualTo: customerId)
          .where('voucherID', isEqualTo: voucher.voucherID)
          .limit(1)
          .get();

      if (ownedVoucherQuery.docs.isNotEmpty) {
        final ownedVoucherDoc = ownedVoucherQuery.docs.first;
        final currentUsage = ownedVoucherDoc.data()['numberOfUses'] as int;
        await ownedVoucherDoc.reference.update({'numberOfUses': currentUsage - 1});
      }

      // Decrease global usageLeft for limited vouchers, except redeemable vouchers.
      if (voucher.isLimited && voucher.displayType != VoucherDisplayType.redeemable) {
        final voucherDoc = await _firestore
            .collection('vouchers')
            .doc(voucher.voucherID)
            .get();

        if (voucherDoc.exists) {
          final currentUsageLeft = voucherDoc.data()?['usageLeft'] as int? ?? 0;
          if (currentUsageLeft > 0) {
            await voucherDoc.reference.update({'usageLeft': currentUsageLeft - 1});
          }
        }
      }

      await Database().updateVoucherLists();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating voucher usage: $e');
        print('Error details: ${e.toString()}');
      }
      // Continue with invoice creation even if voucher update fails
    }
  }

  // Map<String, dynamic>? _serializeAddress(Address? address) {
  //   if (address == null) return null;
  //   return {
  //     'addressID': address.addressID ?? '',
  //     'customerID': address.customerID,
  //     'receiverName': address.receiverName,
  //     'receiverPhone': address.receiverPhone,
  //     'provinceCode': address.province?.code,
  //     'districtCode': address.district?.code,
  //     'wardCode': address.ward?.code,
  //     'street': address.street,
  //     'hidden': address.hidden,
  //   };
  // }

  /// Decrement product stock when invoice is created
  Future<void> _decrementProductStock(
      List<SalesInvoiceDetail> invoiceDetails) async {
    try {
      for (final detail in invoiceDetails) {
        final productID = detail.product.productID;
        if (productID == null || productID.isEmpty) {
          if (kDebugMode) {
            print('Warning: Product ID is missing in invoice detail');
          }
          continue;
        }

        final quantity = detail.quantity;
        if (quantity <= 0) {
          continue;
        }

        final productRef = _firestore.collection('products').doc(productID);
        final productDoc = await productRef.get();

        if (!productDoc.exists) {
          if (kDebugMode) {
            print('Warning: Product not found: $productID');
          }
          continue;
        }

        final productData = productDoc.data()!;
        final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;
        final newStock =
            (currentStock - quantity).clamp(0, double.infinity).toInt();

        await productRef.update({'stock': newStock});

        if (kDebugMode) {
          print(
              'Decremented stock for product $productID: $currentStock -> $newStock (quantity: $quantity)');
        }
      }

      // Refresh products in database to reflect stock changes
      await Database().getProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error decrementing product stock: $e');
        print('Error details: ${e.toString()}');
      }
      // Continue with invoice creation even if stock update fails
      // In production, you might want to rethrow this error
    }
  }

  /// Restore product stock when invoice is cancelled
  Future<void> _restoreProductStock(
      List<Map<String, dynamic>> invoiceDetails) async {
    try {
      for (final detail in invoiceDetails) {
        final productID = detail['productID'] as String?;
        if (productID == null || productID.isEmpty) {
          if (kDebugMode) {
            print('Warning: Product ID is missing in invoice detail');
          }
          continue;
        }

        final quantity = (detail['quantity'] as num?)?.toInt() ?? 0;
        if (quantity <= 0) {
          continue;
        }

        final productRef = _firestore.collection('products').doc(productID);
        final productDoc = await productRef.get();

        if (!productDoc.exists) {
          if (kDebugMode) {
            print('Warning: Product not found: $productID');
          }
          continue;
        }

        final productData = productDoc.data()!;
        final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;
        final newStock = currentStock + quantity;

        await productRef.update({'stock': newStock});

        if (kDebugMode) {
          print(
              'Restored stock for product $productID: $currentStock -> $newStock (quantity: $quantity)');
        }
      }

      // Refresh products in database to reflect stock changes
      await Database().getProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring product stock: $e');
        print('Error details: ${e.toString()}');
      }
    }
  }

  Future<List<ProductImage>> getProductImages(String productId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('images')
          .orderBy('position')
          .get();

      return snapshot.docs.map((doc) {
        return ProductImage.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product images: $e');
      }
      return [];
    }
  }

  /// Get the primary image (position 1) for a product
  Future<ProductImage?> getProductPrimaryImage(String productId) async {
    try {
      // First try to get image with position 1
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('images')
          .where('position', isEqualTo: 1)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ProductImage.fromMap(
          snapshot.docs.first.id,
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }

      // Fallback: If no image with position 1, get the first image ordered by position
      final fallbackSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('images')
          .orderBy('position')
          .limit(1)
          .get();

      if (fallbackSnapshot.docs.isEmpty) {
        return null;
      }

      return ProductImage.fromMap(
        fallbackSnapshot.docs.first.id,
        fallbackSnapshot.docs.first.data(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product primary image: $e');
      }
      return null;
    }
  }

  Future<List<Rating>> getRatingsByProductWithUsername(String productId) async {
    try {
      if (productId.isEmpty) return [];

      // Avoid server-side ordering that requires a composite index.
      // Fetch ratings for the product and sort locally by timeSent descending.
      final QuerySnapshot snapshot = await _firestore
          .collection('order_ratings')
          .where('productID', isEqualTo: productId)
          .get();

      final List<Rating> ratings = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = Rating.fromMap(doc.id, data);

        // Try to fetch username from customers collection using userID
        try {
          if (rating.userID.isNotEmpty) {
            final userDoc = await _firestore
                .collection('customers')
                .doc(rating.userID)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              final customerName = (userData?['customerName'] as String?) ?? '';
              if (customerName.isNotEmpty) {
                rating.username = customerName;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                'Warning: could not fetch username for rating ${rating.ratingID}: $e');
          }
        }

        ratings.add(rating);
      }

      // Sort ratings in-memory by timeSent descending (newest first)
      ratings.sort((a, b) => b.timeSent.compareTo(a.timeSent));

      return ratings;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting ratings by product: $e');
      }
      rethrow;
    }
  }

  Future<RatingsPage> getRatingsPageByProduct(String productId,
      {DocumentSnapshot? startAfter, int limit = 5}) async {
    try {
      if (productId.isEmpty) {
        return RatingsPage(ratings: [], lastDocument: null, hasMore: false);
      }

      Query query = _firestore
          .collection('order_ratings')
          .where('productID', isEqualTo: productId)
          .orderBy('timeSent', descending: true)
          .limit(limit);

      if (startAfter != null) query = query.startAfterDocument(startAfter);

      final QuerySnapshot snapshot = await query.get();

      final List<Rating> ratings = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = Rating.fromMap(doc.id, data);

        // attach username if possible
        try {
          if (rating.userID.isNotEmpty) {
            final userDoc = await _firestore
                .collection('customers')
                .doc(rating.userID)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              final customerName = (userData?['customerName'] as String?) ?? '';
              if (customerName.isNotEmpty) rating.username = customerName;
            }
          }
        } catch (_) {}

        ratings.add(rating);
      }

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit;

      return RatingsPage(
          ratings: ratings, lastDocument: lastDoc, hasMore: hasMore);
    } catch (e) {
      if (kDebugMode) print('Server-side paged query failed: $e');
      rethrow; // let caller handle fallback
    }
  }

  Future<Map<String, dynamic>> getAverageRatingForProduct(
      String productId) async {
    try {
      if (productId.isEmpty) return {'average': 0.0, 'count': 0, 'sum': 0};

      final QuerySnapshot snapshot = await _firestore
          .collection('order_ratings')
          .where('productID', isEqualTo: productId)
          .get();

      int sum = 0;
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ratingVal = data['rating'];
        int parsed = 0;
        if (ratingVal is int) {
          parsed = ratingVal;
        } else if (ratingVal is num) {
          parsed = ratingVal.toInt();
        } else if (ratingVal is String) {
          parsed = int.tryParse(ratingVal) ?? 0;
        } else {
          parsed = 0;
        }
        sum += parsed;
        count += 1;
      }

      final average = (count > 0) ? (sum / count) : 0.0;
      return {'average': average, 'count': count, 'sum': sum};
    } catch (e) {
      if (kDebugMode) print('Error computing average rating: $e');
      return {'average': 0.0, 'count': 0, 'sum': 0};
    }
  }

  /// Get aggregated product rating from Cloud Functions aggregation
  /// Returns null if no aggregated data exists for this product
  Future<Map<String, dynamic>?> getAggregatedProductRating(
      String productId) async {
    try {
      if (productId.isEmpty) return null;

      final doc = await _firestore
          .collection('aggregations')
          .doc('productRatings')
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      final products = data?['products'] as Map<String, dynamic>?;

      if (products == null || !products.containsKey(productId)) {
        return null;
      }

      final productRating = products[productId] as Map<String, dynamic>?;
      if (productRating == null) return null;

      return {
        'avgRating': productRating['avgRating'] ?? 0.0,
        'ratingCount': productRating['ratingCount'] ?? 0,
        'lastUpdated': productRating['lastUpdated'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting aggregated rating for product $productId: $e');
      }
      return null;
    }
  }
}
