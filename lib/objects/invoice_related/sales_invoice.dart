import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/invoice_related/payment_status.dart';
import 'package:gizmoglobe_client/enums/invoice_related/sales_status.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice_detail.dart';

import '../../enums/invoice_related/payment_method.dart';

class SalesInvoice {
  String? salesInvoiceID;
  String customerID;
  String? customerName;
  String address;
  DateTime date;
  SalesStatus salesStatus;
  double totalPrice;
  String? paymentID;
  PaymentMethodEnum paymentMethod;
  PaymentStatus paymentStatus;
  DateTime? paymentDate;
  List<SalesInvoiceDetail> details;

  SalesInvoice({
    this.salesInvoiceID = '',
    required this.customerID,
    this.customerName = '',
    required this.address,
    required this.date,
    required this.salesStatus,
    required this.totalPrice,
    required this.details,
    this.paymentID,
    this.paymentMethod = PaymentMethodEnum.online,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentDate,
  });

  SalesInvoice copyWith({
    String? salesInvoiceID,
    String? customerID,
    String? customerName,
    String? address,
    DateTime? date,
    SalesStatus? salesStatus,
    double? totalPrice,
    List<SalesInvoiceDetail>? details,
    String? paymentID,
    PaymentMethodEnum? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? paymentDate,
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
      paymentID: paymentID ?? this.paymentID,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesInvoiceID': salesInvoiceID,
      'customerID': customerID,
      'customerName': customerName,
      'address': address,
      'date': date,
      'paymentStatus': paymentStatus.getName(),
      'salesStatus': salesStatus.getName(),
      'totalPrice': totalPrice,
      'paymentID': paymentID,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod.getName(),
    };
  }

  static SalesInvoice fromMap(String id, Map<String, dynamic> map) {
    return SalesInvoice(
      salesInvoiceID: id,
      customerID: map['customerID'] ?? '',
      customerName: map['customerName'],
      address: map['address'] ?? '',
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
      paymentID: map['paymentID'],
      paymentDate: map['paymentDate'] != null ? (map['paymentDate'] as Timestamp).toDate() : null,
      paymentMethod: PaymentMethodEnum.values.firstWhere(
        (e) => e.getName() == map['paymentMethod'],
        orElse: () => PaymentMethodEnum.online,
      ),
      details: [],
    );
  }
} 