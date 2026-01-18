import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../data/database/database.dart';

import '../../enums/invoice_related/sales_status.dart';
import '../../enums/manufacturer/manufacturer_status.dart';
import '../../enums/product_related/product_status_enum.dart';
import '../../enums/voucher_related/distribution_type.dart';
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
          rethrow;
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

      // Stock will be decremented after successful payment confirmation
      // This ensures stock is only reduced when payment is actually received

      // Update voucher usage if a voucher was applied
      if (salesInvoice.voucher != null) {
        await _updateVoucherUses(
            salesInvoice.customerID, salesInvoice.voucher!);
      }

      await Database().fetchSalesInvoice();
    } catch (e) {
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
            voucherDiscount: (data['voucherDiscount'] as num?)?.toInt() ?? 0,
          );
        } catch (e) {
          // Continue without voucher if not found
        }
      }

      return salesInvoice;
    } catch (e) {
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
    String? sentiment,
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
          'sentiment': sentiment,
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
          // Could not revert voucher usage
        }
      }

      // Mark invoice as cancelled
      await _firestore.collection('sales_invoices').doc(salesInvoiceID).update({
        'salesStatus': SalesStatus.cancelled.getName(),
      });
      await Database().fetchSalesInvoice();
    } catch (e) {
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
      rethrow;
    }
  }

  Future<List<Voucher>> getVouchers() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('vouchers').get();

      final List<Voucher> vouchers = [];
      // Collect heavy auto-claim tasks and run them after parsing so this function
      // can return quickly and avoid blocking on per-voucher transactions.
      final List<Future<void>> autoClaimTasks = [];

      for (final doc in snapshot.docs) {
        final raw = Map<String, dynamic>.from(doc.data() as Map);
        try {
          final Map<String, dynamic> data = {};

          data['voucherID'] = doc.id;

          data['voucherName'] = (raw['voucherName']?.toString()) ?? '';
          data['enDescription'] = (raw['enDescription']?.toString()) ?? '';
          data['viDescription'] = (raw['viDescription']?.toString()) ?? '';

          data['isEnabled'] =
              raw['isEnabled'] == null ? true : (raw['isEnabled'] == true);
          data['isPercentage'] = raw['isPercentage'] == true;
          data['hasEndTime'] = raw['hasEndTime'] == true;
          data['isLimited'] = raw['isLimited'] == true;

          // parse start and end times into local variables to avoid relying on Voucher getters
          DateTime? startDate;
          DateTime? endDate;

          dynamic start = raw['startTime'];
          if (start is Timestamp) {
            startDate = start.toDate();
          } else if (start is String) {
            try {
              startDate = DateTime.parse(start);
            } catch (_) {
              startDate = DateTime.now();
            }
          } else if (start is DateTime) {
            startDate = start;
          } else {
            startDate = DateTime.now();
          }
          data['startTime'] = startDate;

          if (data['hasEndTime'] == true) {
            dynamic end = raw['endTime'];
            if (end is Timestamp) {
              endDate = end.toDate();
            } else if (end is String) {
              try {
                endDate = DateTime.parse(end);
              } catch (_) {
                endDate = DateTime.now().add(const Duration(days: 30));
              }
            } else if (end is DateTime) {
              endDate = end;
            } else {
              endDate = DateTime.now().add(const Duration(days: 30));
            }
            data['endTime'] = endDate;
          } else {
            data['endTime'] = null;
            endDate = null;
          }

          // Display type: accept string or enum, always pass a string to factory
          final disp = raw['distributionType'];
          if (disp is String) {
            data['distributionType'] = disp;
          } else if (disp is DistributionType) {
            data['distributionType'] = disp.getName();
          } else {
            data['distributionType'] = DistributionType.staffIssued.getName();
          }

          int parseInt(dynamic v, [int def = 0]) {
            if (v is num) return v.toInt();
            if (v is String) return int.tryParse(v) ?? def;
            return def;
          }

          double parseDouble(dynamic v, [double def = 0.0]) {
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? def;
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
            data['maximumDiscountValue'] =
                parseInt(raw['maximumDiscountValue'], 0);
          } else {
            data['maximumDiscountValue'] = 0;
          }

          final voucher = VoucherFactory.fromMap(doc.id, data);
          vouchers.add(voucher);

          try {
            final currentUserId = Database().userID;
            final bool isEveryone =
                voucher.distributionType == DistributionType.public;
            final bool notExpired = data['hasEndTime'] != true ||
                (endDate != null && endDate.isAfter(DateTime.now()));
            final bool started = !startDate.isAfter(DateTime.now());
            if (currentUserId.isNotEmpty &&
                isEveryone &&
                notExpired &&
                started) {
              final int maxPerPerson = (data['maxUsagePerPerson'] as int?) ?? 1;
              final bool voucherIsLimited = voucher.isLimited;
              final String? voucherIdLocal = voucher.voucherID;
              final String userIdLocal = currentUserId;

              autoClaimTasks.add((() async {
                if (voucherIdLocal == null || voucherIdLocal.isEmpty) return;
                try {
                  int toGrant = maxPerPerson;

                  if (voucherIsLimited) {
                    final voucherRef =
                        _firestore.collection('vouchers').doc(voucherIdLocal);
                    final int granted =
                        await _firestore.runTransaction<int>((tx) async {
                      final snap = await tx.get(voucherRef);
                      if (!snap.exists) return 0;

                      final dynamic snapData = snap.data();
                      int currentLeft = 0;
                      if (snapData is Map) {
                        final usageLeftVal = snapData['usageLeft'];
                        if (usageLeftVal is num) {
                          currentLeft = usageLeftVal.toInt();
                        } else if (usageLeftVal is String) {
                          currentLeft = int.tryParse(usageLeftVal) ?? 0;
                        } else {
                          currentLeft = 0;
                        }
                      } else {
                        return 0;
                      }

                      if (currentLeft <= 0) return 0;
                      final int take =
                          toGrant <= currentLeft ? toGrant : currentLeft;
                      tx.update(voucherRef, {'usageLeft': currentLeft - take});
                      return take;
                    });
                    toGrant = granted;
                  }

                  if (toGrant <= 0) return;

                  final ownedCollection =
                      _firestore.collection('owned_vouchers');
                  final existingQuery = await ownedCollection
                      .where('customerID', isEqualTo: userIdLocal)
                      .where('voucherID', isEqualTo: voucherIdLocal)
                      .limit(1)
                      .get();

                  if (existingQuery.docs.isEmpty) {
                    final docRef = ownedCollection.doc();
                    final dataMap = {
                      'customerID': userIdLocal,
                      'voucherID': voucherIdLocal,
                      'numberOfUses': toGrant,
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    await docRef.set(dataMap);
                    await docRef.update({'ownedVoucherID': docRef.id});
                  } else {
                    final docSnap = existingQuery.docs.first;
                    final dynamic existingData = docSnap.data();
                    int currentUses = 0;
                    if (existingData is Map) {
                      final numberVal = existingData['numberOfUses'];
                      if (numberVal is num) {
                        currentUses = numberVal.toInt();
                      } else if (numberVal is String) {
                        currentUses = int.tryParse(numberVal) ?? 0;
                      } else {
                        currentUses = 0;
                      }
                    } else {
                      currentUses = 0;
                    }

                    final needed = toGrant - currentUses;
                    if (needed > 0) {
                      await docSnap.reference
                          .update({'numberOfUses': currentUses + needed});
                    }
                  }
                } catch (e) {
                  // Auto-claim failed - silently continue
                }
              })());
            }
          } catch (e) {
            // Auto-claim check failed - silently continue
          }
        } catch (e, stackTrace) {
          // Failed to parse voucher - log details for debugging
          print('⚠️ Failed to parse voucher ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          print('Raw data keys: ${raw.keys.toList()}');
        }
      }

      // Run queued auto-claim tasks in background (don't await here) and refresh lists once
      if (autoClaimTasks.isNotEmpty) {
        Future.microtask(() async {
          try {
            await Future.wait(autoClaimTasks);
            // Don't call updateVoucherLists here to avoid infinite loop
            // The vouchers are already loaded and will be used
          } catch (e) {
            // Background auto-claim failed - silently continue
          }
        });
      }

      return vouchers;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addOwnedVoucher(OwnedVoucher ownedVoucher) async {
    try {
      final collectionRef = _firestore.collection('owned_vouchers');
      final docRef = await collectionRef.add(ownedVoucher.toMap());
      await docRef.update({'ownedVoucherID': docRef.id});
    } catch (e) {
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
      rethrow;
    }
  }

  Future<OwnedVoucher> redeemVoucher(String customerID, Voucher voucher) async {
    return await _retryOperation(() async {
      if (customerID.isEmpty) {
        throw Exception('Customer ID is required to redeem voucher');
      }

      if (voucher.isLimited) {
        final voucherRef =
            _firestore.collection('vouchers').doc(voucher.voucherID);
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
        final newUses = (updated.data()?['numberOfUses'] as num?)?.toInt() ??
            (currentUses + 1);
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
        await ownedVoucherDoc.reference
            .update({'numberOfUses': currentUsage - 1});
      }

      // Decrease global usageLeft for limited vouchers, except redeemable vouchers.
      if (voucher.isLimited &&
          voucher.distributionType != DistributionType.rewards) {
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

      await Database().updateVoucherLists();
    } catch (e) {
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

  /// Decrement product stock after successful payment confirmation
  Future<void> decrementProductStock(
      List<SalesInvoiceDetail> invoiceDetails) async {
    try {
      for (final detail in invoiceDetails) {
        final productID = detail.product.productID;
        if (productID == null || productID.isEmpty) {
          continue;
        }

        final quantity = detail.quantity;
        if (quantity <= 0) {
          continue;
        }

        final productRef = _firestore.collection('products').doc(productID);
        final productDoc = await productRef.get();

        if (!productDoc.exists) {
          continue;
        }

        final productData = productDoc.data()!;
        final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;
        final newStock =
            (currentStock - quantity).clamp(0, double.infinity).toInt();

        await productRef.update({'stock': newStock});
      }

      // Refresh products in database to reflect stock changes
      await Database().getProducts();
    } catch (e) {
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
          continue;
        }

        final quantity = (detail['quantity'] as num?)?.toInt() ?? 0;
        if (quantity <= 0) {
          continue;
        }

        final productRef = _firestore.collection('products').doc(productID);
        final productDoc = await productRef.get();

        if (!productDoc.exists) {
          continue;
        }

        final productData = productDoc.data()!;
        final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;
        final newStock = currentStock + quantity;

        await productRef.update({'stock': newStock});
      }

      // Refresh products in database to reflect stock changes
      await Database().getProducts();
    } catch (e) {
      // Error restoring product stock
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
          // Warning: could not fetch username for rating
        }

        ratings.add(rating);
      }

      // Sort ratings in-memory by timeSent descending (newest first)
      ratings.sort((a, b) => b.timeSent.compareTo(a.timeSent));

      return ratings;
    } catch (e) {
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
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserSurveyProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('surveyResponses_raw').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        // The actual answers are nested inside the 'raw' map
        if (data != null && data['raw'] is Map) {
          return Map<String, dynamic>.from(data['raw']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
