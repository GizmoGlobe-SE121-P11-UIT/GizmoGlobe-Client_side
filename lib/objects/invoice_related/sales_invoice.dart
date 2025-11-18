import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/invoice_related/payment_method.dart';
import 'package:gizmoglobe_client/enums/invoice_related/payment_status.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../../data/database/database.dart';
import '../address_related/address.dart';
import '../voucher_related/voucher.dart';

class SalesInvoice {
  String? salesInvoiceID;
  String customerID;
  String? customerName;
  Address? address;
  DateTime date;
  SalesStatus salesStatus;
  double totalPrice;
  PaymentStatus paymentStatus;
  PaymentMethod paymentMethod;
  List<SalesInvoiceDetail> details;

  final Voucher? voucher;
  final double voucherDiscount;

  SalesInvoice({
    this.salesInvoiceID = '',
    required this.customerID,
    this.customerName = '',
    this.address,
    required this.date,
    required this.salesStatus,
    required this.totalPrice,
    required this.details,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.cod,
    this.voucher,
    this.voucherDiscount = 0.0,
  });

  List<Object?> get props => [
        salesInvoiceID,
        customerID,
        customerName,
        address,
        date,
        salesStatus,
        totalPrice,
        details,
        paymentStatus,
        paymentMethod,
        voucher,
        voucherDiscount,
      ];

  SalesInvoice copyWith({
    String? salesInvoiceID,
    String? customerID,
    String? customerName,
    Address? address,
    DateTime? date,
    SalesStatus? salesStatus,
    double? totalPrice,
    List<SalesInvoiceDetail>? details,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    Voucher? voucher,
    double? voucherDiscount,
  }) {
    return SalesInvoice(
      salesInvoiceID: salesInvoiceID ?? this.salesInvoiceID,
      customerID: customerID ?? this.customerID,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      date: date ?? this.date,
      salesStatus: salesStatus ?? this.salesStatus,
      totalPrice: totalPrice ?? this.totalPrice,
      details: details ?? this.details,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      voucher: voucher ?? this.voucher,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesInvoiceID': salesInvoiceID,
      'customerID': customerID,
      'customerName': customerName,
      'address': address?.addressID ?? '',
      'date': date,
      'paymentStatus': paymentStatus.getName(),
      'paymentMethod': paymentMethod.getName(),
      'salesStatus': salesStatus.getName(),
      'totalPrice': totalPrice,
      'voucherID': voucher?.voucherID,
      'voucherDiscount': voucherDiscount,
    };
  }

  static SalesInvoice fromMap(String id, Map<String, dynamic> map) {
    Address? address;
    final addressField = map['address'];
    if (addressField is String && addressField.isNotEmpty) {
      try {
        if (Database().addressList.isNotEmpty) {
          address = Database().addressList.firstWhere(
                (addr) => addr.addressID == addressField,
                orElse: () => Address.nullAddress,
              );
          if (address == Address.nullAddress) {
            address = null;
          }
        }
      } catch (e) {
        address = null;
      }
    } else if (addressField is Map<String, dynamic>) {
      address = Address.fromMap({
        'addressID': addressField['addressID'] ?? '',
        'customerID': addressField['customerID'] ?? '',
        'receiverName': addressField['receiverName'] ?? '',
        'receiverPhone': addressField['receiverPhone'] ?? '',
        'provinceCode': addressField['provinceCode'],
        'districtCode': addressField['districtCode'],
        'wardCode': addressField['wardCode'],
        'street': addressField['street'],
        'hidden': addressField['hidden'] ?? false,
      });
      if (address == Address.nullAddress) {
        address = null;
      }
    }

    final dateValue = map['date'];
    DateTime parsedDate;
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (dateValue is DateTime) {
      parsedDate = dateValue;
    } else {
      parsedDate = DateTime.now();
    }

    return SalesInvoice(
      salesInvoiceID: id,
      customerID: map['customerID'] ?? '',
      customerName: map['customerName'],
      address: address,
      date: parsedDate,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.getName() == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.getName() == map['paymentMethod'],
        orElse: () => PaymentMethod.cod,
      ),
      salesStatus: SalesStatus.values.firstWhere(
        (e) => e.getName() == map['salesStatus'],
        orElse: () => SalesStatus.pending,
      ),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      details: [],
    );
  }

  bool hasDiscount() {
    return details.any((detail) => detail.product.discount > 0);
  }

  double getTotalBasedPrice() {
    return details.fold(
        0, (previousValue, element) => previousValue + element.subtotal);
  }

  int getTotalItems() {
    return details.fold(
        0, (previousValue, detail) => previousValue + detail.quantity);
  }
}
