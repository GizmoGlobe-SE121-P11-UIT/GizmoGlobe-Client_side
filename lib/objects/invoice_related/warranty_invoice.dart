import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gizmoglobe_client/enums/invoice_related/warranty_status.dart';
import 'package:gizmoglobe_client/objects/invoice_related/warranty_invoice_detail.dart';

class WarrantyInvoice {
  String? warrantyInvoiceID;
  String customerID;
  DateTime date;
  WarrantyStatus status;
  String reason;
  List<WarrantyInvoiceDetail> details;

  WarrantyInvoice({
    this.warrantyInvoiceID,
    required this.customerID,
    required this.date,
    required this.status,
    required this.reason,
    this.details = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'customerID': customerID,
      'date': Timestamp.fromDate(date),
      'status': status.getName(),
      'reason': reason,
    };
  }

  static WarrantyInvoice fromMap(String id, Map<String, dynamic> map) {
    return WarrantyInvoice(
      warrantyInvoiceID: id,
      customerID: map['customerID'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: WarrantyStatus.values.firstWhere(
        (e) => e.getName().toLowerCase() == (map['status'] as String? ?? 'pending').toLowerCase(),
        orElse: () => WarrantyStatus.pending,
      ),
      reason: map['reason'] ?? '',
    );
  }
} 