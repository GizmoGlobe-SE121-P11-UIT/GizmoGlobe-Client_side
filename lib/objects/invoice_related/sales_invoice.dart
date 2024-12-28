import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/invoice_related/payment_status.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';
import '../address_related/address.dart';

class SalesInvoice {
  String? salesInvoiceID;
  String customerID;
  String? customerName;
  Address? address;
  DateTime date;
  SalesStatus salesStatus;
  double totalPrice;
  PaymentStatus paymentStatus;
  List<SalesInvoiceDetail> details;

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
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesInvoiceID': salesInvoiceID,
      'customerID': customerID,
      'customerName': customerName,
      'address': address!.addressID != '' ? address!.addressID : '',
      'date': date,
      'paymentStatus': paymentStatus.getName(),
      'salesStatus': salesStatus.getName(),
      'totalPrice': totalPrice,
    };
  }

  static SalesInvoice fromMap(String id, Map<String, dynamic> map) {
    return SalesInvoice(
      salesInvoiceID: id,
      customerID: map['customerID'] ?? '',
      customerName: map['customerName'],
      address: map['address'] != null ? Address.fromMap(map['address']) : Address.nullAddress,
      date: (map['date'] as Timestamp).toDate(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.getName() == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
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
    return details.fold(0, (previousValue, detail) => previousValue + detail.product.price * detail.quantity);
  }
} 