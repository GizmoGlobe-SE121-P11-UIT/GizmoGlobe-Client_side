import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/invoice_related/payment_status.dart';
import 'package:gizmoglobe_client/objects/invoice_related/incoming_invoice_detail.dart';

class IncomingInvoice {
  String? incomingInvoiceID;
  String manufacturerID;
  DateTime date;
  PaymentStatus status;
  double totalPrice;
  List<IncomingInvoiceDetail> details;

  IncomingInvoice({
    this.incomingInvoiceID,
    required this.manufacturerID,
    required this.date,
    required this.status,
    required this.totalPrice,
    this.details = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'manufacturerID': manufacturerID,
      'date': Timestamp.fromDate(date),
      'status': status.getName(),
      'totalPrice': totalPrice,
    };
  }

  static IncomingInvoice fromMap(String id, Map<String, dynamic> map) {
    return IncomingInvoice(
      incomingInvoiceID: id,
      manufacturerID: map['manufacturerID'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.getName().toLowerCase() == (map['status'] as String? ?? 'pending').toLowerCase(),
        orElse: () => PaymentStatus.unpaid,
      ),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }
} 