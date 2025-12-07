import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/database/database.dart';

import '../../enums/invoice_related/sales_status.dart';
import '../../enums/manufacturer/manufacturer_status.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../objects/address_related/address.dart';
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
      await _firestore.collection('sales_invoices').doc(salesInvoiceID).set({
        'salesInvoiceID': salesInvoiceID,
        'customerID': salesInvoice.customerID,
        'customerName': salesInvoice.customerName ?? '',
        'address': _serializeAddress(salesInvoice.address),
        'date': salesInvoice.date,
        'paymentStatus': salesInvoice.paymentStatus.getName(),
        'paymentMethod': salesInvoice.paymentMethod.getName(),
        'salesStatus': salesInvoice.salesStatus.getName(),
        'totalPrice': salesInvoice.totalPrice,
        'voucherID': salesInvoice.voucher?.voucherID,
        'voucherDiscount': salesInvoice.voucherDiscount,
      });

      for (SalesInvoiceDetail detail in salesInvoice.details) {
        await _firestore
            .collection('sales_invoice_details')
            .add(detail.toMap(salesInvoiceID));
      }

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
      await invoiceRef.update({
        'salesInvoiceID': salesInvoice.salesInvoiceID,
        'customerID': salesInvoice.customerID,
        'customerName': salesInvoice.customerName ?? '',
        'address': _serializeAddress(salesInvoice.address),
        'date': salesInvoice.date,
        'paymentStatus': salesInvoice.paymentStatus.getName(),
        'paymentMethod': salesInvoice.paymentMethod.getName(),
        'salesStatus': salesInvoice.salesStatus.getName(),
        'totalPrice': salesInvoice.totalPrice,
        'voucherID': salesInvoice.voucher?.voucherID,
        'voucherDiscount': salesInvoice.voucherDiscount,
      });

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
      final userID = Database().userID.isEmpty
          ? (await Database().getCurrentUserID() ?? '')
          : Database().userID;
      if (userID.isEmpty) {
        return [];
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .where('customerID', isEqualTo: userID)
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

          // Try to find product in fullProductList first, then productList
          final product = Database().fullProductList.firstWhere(
            (product) => product.productID == productID,
            orElse: () {
              // Fallback to productList if not found in fullProductList
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
            sellingPrice: (detailData['sellingPrice'] as num).toDouble(),
            subtotal: (detailData['subtotal'] as num).toDouble(),
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
            // Fallback to productList if not found in fullProductList
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
          sellingPrice: (detailData['sellingPrice'] as num).toDouble(),
          subtotal: (detailData['subtotal'] as num).toDouble(),
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

  Future<void> confirmDelivery(SalesInvoice salesInvoice) async {
    try {
      await _firestore
          .collection('sales_invoices')
          .doc(salesInvoice.salesInvoiceID)
          .update({
        'salesStatus': SalesStatus.completed.getName(),
      });
      await Database().fetchSalesInvoice();
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming delivery: $e');
      }
      // print('Lỗi khi xác nhận giao hàng: $e');
      rethrow;
    }
  }

  /// Cancel a sales invoice (mark as cancelled status)
  /// Optionally reverts voucher usage if a voucher was applied
  Future<void> cancelSalesInvoice(String salesInvoiceID,
      {bool revertVoucherUsage = true}) async {
    try {
      // Get the invoice to check if it has a voucher
      final invoiceDoc = await _firestore
          .collection('sales_invoices')
          .doc(salesInvoiceID)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Invoice not found: $salesInvoiceID');
      }

      final invoiceData = invoiceDoc.data() as Map<String, dynamic>;
      final voucherID = invoiceData['voucherID'] as String?;

      // Revert voucher usage if voucher was applied and revertVoucherUsage is true
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
          // Continue with cancellation even if voucher revert fails
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

  /// Delete a sales invoice and its details (use with caution)
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
      final QuerySnapshot snapshot =
          await _firestore.collection('vouchers').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['voucherID'] = doc.id;

        // Convert date strings to DateTime objects and ensure startTime is never null
        if (data['startTime'] is String) {
          data['startTime'] = DateTime.parse(data['startTime']);
        } else if (data['startTime'] == null) {
          data['startTime'] = DateTime.now();
        }

        // Handle endTime for vouchers with end time
        if (data['hasEndTime'] == true) {
          if (data['endTime'] is String) {
            data['endTime'] = DateTime.parse(data['endTime']);
          } else if (data['endTime'] == null) {
            data['endTime'] = DateTime.now()
                .add(const Duration(days: 30)); // Default to 30 days from now
          }
        }

        // Handle required fields with default values
        data['voucherName'] ??= '';
        data['discountValue'] ??= 0.0;
        data['minimumPurchase'] ??= 0;
        data['maxUsagePerPerson'] ??= 1;
        data['isVisible'] ??= true;
        data['isEnabled'] ??= true;
        data['enDescription'] ??= '';
        data['viDescription'] ??= '';
        data['isPercentage'] ??= false;
        data['hasEndTime'] ??= false;
        data['isLimited'] ??= false;

        // Handle fields for limited vouchers
        if (data['isLimited'] == true) {
          data['maximumUsage'] ??= 0;
          data['usageLeft'] ??= 0;
        }

        // Handle fields for percentage vouchers
        if (data['isPercentage'] == true) {
          data['maximumDiscountValue'] ??= 0;
        }

        // Ensure all DateTime fields are properly set
        if (data['startTime'] is! DateTime) {
          data['startTime'] = DateTime.now();
        }
        if (data['hasEndTime'] == true && data['endTime'] is! DateTime) {
          data['endTime'] = DateTime.now().add(const Duration(days: 30));
        }

        return VoucherFactory.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vouchers: $e');
      }
      rethrow;
    }
  }

  Future<List<OwnedVoucher>> getOwnedVouchers() async {
    final QuerySnapshot snapshot = await _firestore
        .collection('owned_vouchers')
        .where('customerID', isEqualTo: Database().userID)
        .where('numberOfUses', isGreaterThan: 0)
        .get();
    return snapshot.docs.map((doc) {
      return OwnedVoucher.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
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

  Future<List<OwnedVoucher>> getOwnedVouchersByCustomerId(
      String customerId) async {
    try {
      // Using a simple where clause without sorting to avoid needing a composite index
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
      // 1. Increase owned voucher usage count (revert the reduction)
      final ownedVoucherQuery = await _firestore
          .collection('owned_vouchers')
          .where('customerID', isEqualTo: customerId)
          .where('voucherID', isEqualTo: voucher.voucherID)
          .limit(1)
          .get();

      if (ownedVoucherQuery.docs.isNotEmpty) {
        final ownedVoucherDoc = ownedVoucherQuery.docs.first;
        final currentUsage = ownedVoucherDoc.data()['numberOfUses'] as int;
        // Increase usage by 1 to revert the previous reduction
        await ownedVoucherDoc.reference
            .update({'numberOfUses': currentUsage + 1});
      }
      // 2. If it's a limited voucher, increase usageLeft by 1 (revert the reduction)
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
      // 1. Reduce owned voucher usage count
      final ownedVoucherQuery = await _firestore
          .collection('owned_vouchers')
          .where('customerID', isEqualTo: customerId)
          .where('voucherID', isEqualTo: voucher.voucherID)
          .limit(1)
          .get();

      if (ownedVoucherQuery.docs.isNotEmpty) {
        final ownedVoucherDoc = ownedVoucherQuery.docs.first;
        final currentUsage = ownedVoucherDoc.data()['numberOfUses'] as int;
        // Reduce usage by 1
        await ownedVoucherDoc.reference
            .update({'numberOfUses': currentUsage - 1});
      }

      // 2. If it's a limited voucher, reduce usageLeft by 1
      if (voucher.isLimited) {
        final voucherDoc = await _firestore
            .collection('vouchers')
            .doc(voucher.voucherID)
            .get();

        if (voucherDoc.exists) {
          final currentUsageLeft = voucherDoc.data()?['usageLeft'] as int? ?? 0;
          if (currentUsageLeft > 0) {
            await voucherDoc.reference
                .update({'usageLeft': currentUsageLeft - 1});
          }
        }
      }

      // Update local voucher lists to reflect changes
      await Database().updateVoucherLists();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating voucher usage: $e');
        print('Error details: ${e.toString()}');
      }
      // Continue with invoice creation even if voucher update fails
    }
  }

  Map<String, dynamic>? _serializeAddress(Address? address) {
    if (address == null) return null;
    return {
      'addressID': address.addressID ?? '',
      'customerID': address.customerID,
      'receiverName': address.receiverName,
      'receiverPhone': address.receiverPhone,
      'provinceCode': address.province?.code,
      'districtCode': address.district?.code,
      'wardCode': address.ward?.code,
      'street': address.street,
      'hidden': address.hidden,
    };
  }

  /// Get all images for a product from the images subcollection
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
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('images')
          .where('position', isEqualTo: 1)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ProductImage.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting product primary image: $e');
      }
      return null;
    }
  }
}
