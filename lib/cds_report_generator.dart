import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CDSReportGenerator {
  static Future<void> generatePanchayatReport({
    required String panchayat,
    required String chairperson,
    required int totalMembers,
    required int totalADS,
    required double savings,
    required double loans,
  }) async {
    final pdf = pw.Document();
    final dateString = DateFormat('dd-MM-yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- Header ---
                pw.Center(
                  child: pw.Text("K-SHREE KUDUMBASHREE MANAGEMENT",
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal)),
                ),
                pw.Center(
                  child: pw.Text("CDS Monthly Performance Report",
                      style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.Divider(thickness: 2, color: PdfColors.teal),
                pw.SizedBox(height: 20),

                // --- Metadata ---
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Panchayat: ${panchayat.toUpperCase()}"),
                      pw.Text("Date: $dateString"),
                    ]),
                pw.Text("Chairperson: $chairperson"),
                pw.SizedBox(height: 30),

                // --- Summary Table ---
                pw.Text("Administrative Summary",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.teal),
                  data: [
                    ['Metric', 'Current Count'],
                    ['Total Members Registered', '$totalMembers'],
                    ['Active ADS Units', '$totalADS'],
                  ],
                ),
                pw.SizedBox(height: 30),

                // --- Financial Section ---
                pw.Text("Financial Standing",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Column(children: [
                    _buildPdfRow("Total Savings Collected",
                        "Rs. ${savings.toStringAsFixed(2)}"),
                    _buildPdfRow("Total Loans Disbursed",
                        "Rs. ${loans.toStringAsFixed(2)}"),
                    pw.Divider(),
                    _buildPdfRow("Net Fund Turnover",
                        "Rs. ${(savings + loans).toStringAsFixed(2)}"),
                  ]),
                ),
                pw.Spacer(),

                // --- Footer / Signatures ---
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(children: [
                        // FIXED: Added pw.BoxDecoration to handle the border
                        pw.Container(
                            width: 100,
                            decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                    top: pw.BorderSide(
                                        color: PdfColors.black, width: 1)))),
                        pw.Text("Secretary Signature",
                            style: const pw.TextStyle(fontSize: 10)),
                      ]),
                      pw.Column(children: [
                        // FIXED: Added pw.BoxDecoration to handle the border
                        pw.Container(
                            width: 100,
                            decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                    top: pw.BorderSide(
                                        color: PdfColors.black, width: 1)))),
                        pw.Text("CDS Chairperson",
                            style: const pw.TextStyle(fontSize: 10)),
                      ]),
                    ]),
              ],
            ),
          );
        },
      ),
    );

    // Preview/Download the PDF
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label),
            pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ]),
    );
  }
}