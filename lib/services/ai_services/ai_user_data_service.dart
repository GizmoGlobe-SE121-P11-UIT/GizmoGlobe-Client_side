import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../functions/helper.dart';

class AIUserDataService {
  final FirebaseFirestore _firestore;

  AIUserDataService(this._firestore);

  /// Get user favorites
  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      final favoriteSnapshot = await _firestore
          .collection('customers')
          .doc(userId)
          .collection('favorites')
          .get();

      final favoriteProductIDs =
          favoriteSnapshot.docs.map((doc) => doc.id).toList();

      if (favoriteProductIDs.isEmpty) {
        return [];
      }

      final productSnapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: favoriteProductIDs)
          .get();

      return productSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'productID': doc.id,
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user cart
  Future<List<Map<String, dynamic>>> getUserCart(String userId) async {
    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .collection('carts')
          .get();

      if (cartSnapshot.docs.isEmpty) {
        return [];
      }

      final cartItems = cartSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productID': data['productID'],
          'quantity': data['quantity'],
          'docId': doc.id,
        };
      }).toList();

      final products = await Future.wait(
        cartItems.map((item) async {
          final productID = item['productID'];

          // Try both collections
          var productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productID)
              .get();

          if (!productDoc.exists) {
            productDoc = await FirebaseFirestore.instance
                .collection('items')
                .doc(productID)
                .get();
          }

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            return {
              ...productData,
              'quantity': item['quantity'],
              'cartDocId': item['docId'],
            };
          }
          return null;
        }),
      );

      final validProducts = products.whereType<Map<String, dynamic>>().toList();
      return validProducts;
    } catch (e) {
      return [];
    }
  }

  /// Get user invoices
  Future<List<Map<String, dynamic>>> getUserInvoices(String userId) async {
    try {
      final invoiceSnapshot = await FirebaseFirestore.instance
          .collection('sales_invoices')
          .where('customerID', isEqualTo: userId)
          .get();

      if (invoiceSnapshot.docs.isEmpty) {
        return [];
      }

      final invoices = invoiceSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          ...data,
          'docId': doc.id,
        };
      }).toList();

      return invoices;
    } catch (e) {
      return [];
    }
  }

  /// Get available vouchers
  Future<List<Map<String, dynamic>>> getVouchers() async {
    try {
      final voucherSnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('isEnabled', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .get();

      if (voucherSnapshot.docs.isEmpty) {
        return [];
      }

      final vouchers = voucherSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'docId': doc.id,
        };
      }).toList();

      return vouchers;
    } catch (e) {
      return [];
    }
  }

  /// Format favorites list
  String formatFavoritesList(
      List<Map<String, dynamic>> favorites, bool isVietnamese) {
    if (favorites.isEmpty) {
      return isVietnamese
          ? 'Bạn chưa có sản phẩm yêu thích nào.'
          : 'You have no favorite products yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln(isVietnamese ? 'DANH SACH YEU THICH:' : 'FAVORITE LIST:');

    for (var i = 0; i < favorites.length; i++) {
      final product = favorites[i];
      final price = (product['sellingPrice'] ?? 0.0) as num;
      final discount = (product['discount'] ?? 0.0) as num;
      // Discount is stored as percentage (0-100), not multiplier (0-1)
      final discountedPrice = price * (1 - discount.toDouble() / 100);

      buffer.writeln('\n${i + 1}. ${product['productName']}');
      buffer.writeln('   Gia: ${Helper.toCurrencyFormat(discountedPrice)}');
      buffer.writeln('   Kho: ${formatValue(product['stock'], 'stock')}');
    }

    return buffer.toString();
  }

  /// Format cart list
  String formatCartList(
      List<Map<String, dynamic>> cartItems, bool isVietnamese) {
    if (cartItems.isEmpty) {
      return isVietnamese
          ? 'Giỏ hàng của bạn đang trống.'
          : 'Your cart is empty.';
    }

    final buffer = StringBuffer();
    final totalItems = cartItems.fold<int>(
        0, (acc, item) => acc + (item['quantity'] as int? ?? 0));
    final totalProducts = cartItems.length;
    final totalValue = cartItems.fold<double>(0.0, (acc, item) {
      final price = (item['sellingPrice'] ?? 0.0) as num;
      final discount = (item['discount'] ?? 0.0) as num;
      // Discount is stored as percentage (0-100), not multiplier (0-1)
      final discountedPrice = price * (1 - discount.toDouble() / 100);
      final quantity = (item['quantity'] ?? 0) as int;
      return acc + (discountedPrice * quantity);
    });

    if (isVietnamese) {
      buffer.writeln('Danh sách sản phẩm trong giỏ hàng:');
      buffer.writeln(
          '📊 Tổng: $totalItems sản phẩm (từ $totalProducts loại) - ${Helper.toCurrencyFormat(totalValue)}');
      buffer.writeln('----------------------------------------');
      for (var item in cartItems) {
        final name = item['productName'] ?? 'Unknown Product';
        final price = (item['sellingPrice'] ?? 0.0) as num;
        final discount = (item['discount'] ?? 0.0) as num;
        // Discount is stored as percentage (0-100), not multiplier (0-1)
        final discountedPrice = price * (1 - discount.toDouble() / 100);
        final quantity = item['quantity'] ?? 0;
        final total = discountedPrice * quantity;
        final stock = item['stock'] ?? 0;
        final stockStatus = stock > 0 ? '🟢 Còn hàng' : '🔴 Hết hàng';

        buffer.writeln('📦 $name');
        buffer.writeln('💰 Giá: ${Helper.toCurrencyFormat(discountedPrice)}');
        buffer.writeln('🔢 Số lượng: $quantity');
        buffer.writeln('💵 Tổng: ${Helper.toCurrencyFormat(total)}');
        buffer.writeln('📊 $stockStatus');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Items in your cart:');
      buffer.writeln(
          '📊 Total: $totalItems items (from $totalProducts products) - ${Helper.toCurrencyFormat(totalValue)}');
      buffer.writeln('----------------------------------------');
      for (var item in cartItems) {
        final name = item['productName'] ?? 'Unknown Product';
        final price = (item['sellingPrice'] ?? 0.0) as num;
        final discount = (item['discount'] ?? 0.0) as num;
        // Discount is stored as percentage (0-100), not multiplier (0-1)
        final discountedPrice = price * (1 - discount.toDouble() / 100);
        final quantity = item['quantity'] ?? 0;
        final total = discountedPrice * quantity;
        final stock = item['stock'] ?? 0;
        final stockStatus = stock > 0 ? '🟢 In Stock' : '🔴 Out of Stock';

        buffer.writeln('📦 $name');
        buffer.writeln('💰 Price: ${Helper.toCurrencyFormat(discountedPrice)}');
        buffer.writeln('🔢 Quantity: $quantity');
        buffer.writeln('💵 Total: ${Helper.toCurrencyFormat(total)}');
        buffer.writeln('📊 $stockStatus');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  /// Format invoice list
  String formatInvoiceList(
      List<Map<String, dynamic>> invoices, bool isVietnamese) {
    if (invoices.isEmpty) {
      return isVietnamese
          ? 'Bạn chưa có hóa đơn nào.'
          : 'You have no invoices.';
    }

    final buffer = StringBuffer();
    if (isVietnamese) {
      buffer.writeln('Danh sách hóa đơn:');
      buffer.writeln('----------------------------------------');
      for (var invoice in invoices) {
        final date = (invoice['date'] as Timestamp).toDate();
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
        final totalPrice = invoice['totalPrice'] ?? 0.0;
        final paymentStatus = invoice['paymentStatus'] ?? 'unknown';
        final salesStatus = invoice['salesStatus'] ?? 'unknown';

        buffer.writeln('📄 Mã hóa đơn: ${invoice['salesInvoiceID']}');
        buffer.writeln('📅 Ngày: $formattedDate');
        buffer.writeln('💰 Tổng tiền: ${Helper.toCurrencyFormat(totalPrice)}');
        buffer.writeln(
            '💳 Trạng thái thanh toán: ${formatStatus(paymentStatus, isVietnamese)}');
        buffer.writeln(
            '📦 Trạng thái đơn hàng: ${formatStatus(salesStatus, isVietnamese)}');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Invoice List:');
      buffer.writeln('----------------------------------------');
      for (var invoice in invoices) {
        final date = (invoice['date'] as Timestamp).toDate();
        final formattedDate = DateFormat('MM/dd/yyyy HH:mm').format(date);
        final totalPrice = invoice['totalPrice'] ?? 0.0;
        final paymentStatus = invoice['paymentStatus'] ?? 'unknown';
        final salesStatus = invoice['salesStatus'] ?? 'unknown';

        buffer.writeln('📄 Invoice ID: ${invoice['salesInvoiceID']}');
        buffer.writeln('📅 Date: $formattedDate');
        buffer.writeln('💰 Total: ${Helper.toCurrencyFormat(totalPrice)}');
        buffer.writeln(
            '💳 Payment Status: ${formatStatus(paymentStatus, isVietnamese)}');
        buffer.writeln(
            '📦 Order Status: ${formatStatus(salesStatus, isVietnamese)}');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  /// Format voucher list
  String formatVoucherList(
      List<Map<String, dynamic>> vouchers, bool isVietnamese) {
    if (vouchers.isEmpty) {
      return isVietnamese
          ? 'Hiện không có voucher nào khả dụng.'
          : 'No vouchers available at the moment.';
    }

    final buffer = StringBuffer();
    if (isVietnamese) {
      buffer.writeln('Danh sách voucher khả dụng:');
      buffer.writeln('----------------------------------------');
      for (var voucher in vouchers) {
        final name = voucher['voucherName'] ?? 'Unknown Voucher';
        final discountValue = voucher['discountValue'] ?? 0;
        final isPercentage = voucher['isPercentage'] ?? false;
        final minPurchase = voucher['minimumPurchase'] ?? 0;
        final maxDiscount = voucher['maximumDiscountValue'] ?? 0;
        final description =
            voucher['description'] ?? voucher['viDescription'] ?? '';
        final startTime = parseDate(voucher['startTime']);
        final endTime = parseDate(voucher['endTime']);

        buffer.writeln('🎟️ $name');
        buffer.writeln(
            '💰 Giảm giá: ${isPercentage ? '$discountValue%' : Helper.toCurrencyFormat(discountValue)}');
        buffer.writeln(
            '💵 Áp dụng cho đơn hàng từ: ${Helper.toCurrencyFormat(minPurchase)}');
        buffer
            .writeln('🎯 Giảm tối đa: ${Helper.toCurrencyFormat(maxDiscount)}');
        buffer.writeln(
            '📅 Thời gian: ${DateFormat('dd/MM/yyyy').format(startTime)} - ${DateFormat('dd/MM/yyyy').format(endTime)}');
        buffer.writeln('📝 $description');
        buffer.writeln('----------------------------------------');
      }
    } else {
      buffer.writeln('Available Vouchers:');
      buffer.writeln('----------------------------------------');
      for (var voucher in vouchers) {
        final name = voucher['voucherName'] ?? 'Unknown Voucher';
        final discountValue = voucher['discountValue'] ?? 0;
        final isPercentage = voucher['isPercentage'] ?? false;
        final minPurchase = voucher['minimumPurchase'] ?? 0;
        final maxDiscount = voucher['maximumDiscountValue'] ?? 0;
        final description =
            voucher['description'] ?? voucher['enDescription'] ?? '';
        final startTime = parseDate(voucher['startTime']);
        final endTime = parseDate(voucher['endTime']);

        buffer.writeln('🎟️ $name');
        buffer.writeln(
            '💰 Discount: ${isPercentage ? '$discountValue%' : Helper.toCurrencyFormat(discountValue)}');
        buffer.writeln(
            '💵 Apply for orders from: ${Helper.toCurrencyFormat(minPurchase)}');
        buffer.writeln(
            '🎯 Maximum discount: ${Helper.toCurrencyFormat(maxDiscount)}');
        buffer.writeln(
            '📅 Valid: ${DateFormat('MM/dd/yyyy').format(startTime)} - ${DateFormat('MM/dd/yyyy').format(endTime)}');
        buffer.writeln('📝 $description');
        buffer.writeln('----------------------------------------');
      }
    }
    return buffer.toString();
  }

  // Private helper methods
  DateTime parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    return DateTime.now(); // fallback
  }

  String formatStatus(String status, bool isVietnamese) {
    final statusMap = {
      'paid': {'en': 'Paid', 'vi': 'Đã thanh toán'},
      'pending': {'en': 'Pending', 'vi': 'Đang xử lý'},
      'cancelled': {'en': 'Cancelled', 'vi': 'Đã hủy'},
      'shipped': {'en': 'Shipped', 'vi': 'Đã giao hàng'},
      'delivered': {'en': 'Delivered', 'vi': 'Đã nhận hàng'},
      'unknown': {'en': 'Unknown', 'vi': 'Không xác định'},
    };

    return statusMap[status]?[isVietnamese ? 'vi' : 'en'] ?? status;
  }

  String formatValue(dynamic value, String type) {
    if (value == null) return 'N/A';

    switch (type) {
      case 'stock':
        if (value is num) {
          final stock = value as int;
          return stock > 0 ? 'In Stock ($stock units)' : 'Out of Stock';
        }
        return 'Stock status unknown';
      default:
        return value.toString();
    }
  }
}
