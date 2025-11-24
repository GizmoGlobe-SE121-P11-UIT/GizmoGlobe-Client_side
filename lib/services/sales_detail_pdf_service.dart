import 'package:flutter/services.dart' show rootBundle;
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/objects/invoice_related/sales_invoice.dart';
import 'package:gizmoglobe_client/objects/product_related/product.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SalesInvoicePdfService {
  static const _regularFontAsset = 'assets/fonts/NotoSans-Regular.ttf';
  static const _boldFontAsset = 'assets/fonts/NotoSans-Bold.ttf';
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Document> generatePdf({
    required SalesInvoice invoice,
    required Map<String, Product> products,
  }) async {
    final notoSansRegular = await _loadRegularFont();
    final notoSansBold = await _loadBoldFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Theme(
            data: pw.ThemeData.withFont(
              base: notoSansRegular,
              bold: notoSansBold,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(notoSansRegular, notoSansBold),
                pw.SizedBox(height: 40),
                _buildInvoiceInfo(invoice, notoSansRegular, notoSansBold),
                pw.SizedBox(height: 20),
                _buildProductsTable(
                  invoice,
                  products,
                  notoSansRegular,
                  notoSansBold,
                ),
                pw.SizedBox(height: 20),
                _buildFooter(invoice, notoSansBold),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Font> _loadRegularFont() async {
    final cached = _cachedRegularFont;
    if (cached != null) {
      return cached;
    }
    final font = await _loadFont(_regularFontAsset);
    _cachedRegularFont = font;
    return font;
  }

  static Future<pw.Font> _loadBoldFont() async {
    final cached = _cachedBoldFont;
    if (cached != null) {
      return cached;
    }
    final font = await _loadFont(_boldFontAsset);
    _cachedBoldFont = font;
    return font;
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        Exception('Failed to load font asset: $assetPath'),
        stackTrace,
      );
    }
  }

  static pw.Widget _buildHeader(
    pw.Font notoSansRegular,
    pw.Font notoSansBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: PdfColors.green700,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GIZMOGLOBE',
                style: pw.TextStyle(
                  font: notoSansBold,
                  color: PdfColors.white,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Retailer Management System',
                style: pw.TextStyle(
                  font: notoSansRegular,
                  color: PdfColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          pw.Text(
            'SALES INVOICE',
            style: pw.TextStyle(
              font: notoSansBold,
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceInfo(
    SalesInvoice invoice,
    pw.Font notoSansRegular,
    pw.Font notoSansBold,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final addressText = invoice.address?.toString(isEnglish: true) ?? 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green400, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Invoice ID:',
            invoice.salesInvoiceID ?? '',
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Date:',
            dateFormat.format(invoice.date),
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Customer:',
            invoice.customerName?.isNotEmpty == true
                ? invoice.customerName!
                : invoice.customerID,
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Payment method:',
            invoice.paymentMethod.enDescription,
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Status:',
            invoice.paymentStatus.getName().toUpperCase(),
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Sales status:',
            invoice.salesStatus.getName().toUpperCase(),
            notoSansBold,
            notoSansRegular,
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
            'Address:',
            addressText,
            notoSansBold,
            notoSansRegular,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 12),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProductsTable(
    SalesInvoice invoice,
    Map<String, Product> products,
    pw.Font notoSansRegular,
    pw.Font notoSansBold,
  ) {
    final tableHeaders = [
      'Product',
      'Product ID',
      'Quantity',
      'Unit Price',
      'Subtotal',
    ];

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.green700),
        children: tableHeaders.map((header) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                font: notoSansBold,
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    ];

    for (final detail in invoice.details) {
      final productId = detail.product.productID ?? '';
      final product = products[productId] ?? detail.product;
      final unitPrice = detail.sellingPrice.toDouble();
      final subtotal = detail.subtotal;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                product.productName,
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                productId.isNotEmpty ? productId : 'N/A',
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '${detail.quantity}',
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                Helper.toCurrencyFormat(unitPrice),
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                Helper.toCurrencyFormat(subtotal),
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    if (rows.length == 1) {
      rows.add(
        pw.TableRow(
          children: List.generate(
            tableHeaders.length,
            (_) => pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'No products available',
                style: pw.TextStyle(font: notoSansRegular, fontSize: 10),
              ),
            ),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.green400, width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  static pw.Widget _buildFooter(
    SalesInvoice invoice,
    pw.Font notoSansBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green300, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOTAL AMOUNT:',
            style: pw.TextStyle(
              font: notoSansBold,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.Text(
            Helper.toCurrencyFormat(invoice.totalPrice),
            style: pw.TextStyle(
              font: notoSansBold,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ],
      ),
    );
  }
}
