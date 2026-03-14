import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../features/reports/models/report_model.dart';
import 'currency_formatter.dart';

class PdfGenerator {
  static Future<Uint8List> generateReport(MonthlyReport report, String communityName) async {
    final pdf = pw.Document();
    
    // Gunakan font bawaan library PDF
    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();
    
    final monthName = DateFormat('MMMM', 'id_ID').format(DateTime(report.year, report.month));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN KEUANGAN', style: pw.TextStyle(font: ttfBold, fontSize: 18, color: PdfColors.blue900)),
                    pw.Text('Lingkungan $communityName', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Periode', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                    pw.Text('$monthName ${report.year}', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 20),
            
            // Ringkasan
            pw.Text('Ringkasan Bulan Ini', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Total Pemasukan', report.totalIncome, ttf, ttfBold, PdfColors.green700),
                  _buildSummaryItem('Total Pengeluaran', report.totalExpense, ttf, ttfBold, PdfColors.red700),
                  _buildSummaryItem('Saldo Bersih', report.netBalance, ttf, ttfBold, PdfColors.blue900),
                ]
              )
            ),
            
            pw.SizedBox(height: 20),
            
            // Kolektibilitas
            pw.Text('Kolektibilitas Tagihan: ${report.collectionRate.toStringAsFixed(1)}%', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
            pw.Text('Terkumpul ${CurrencyFormatter.format(report.totalIncome)} dari target ${CurrencyFormatter.format(report.totalExpected)}', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600)),
            
            pw.SizedBox(height: 40),
            
            // Tanda Tangan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Dibuat pada ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.SizedBox(height: 60),
                    pw.Text('Pengurus RW', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                  ]
                )
              ]
            )
          ];
        },
      ),
    );

    
    return await pdf.save();
  }
  
  static pw.Widget _buildSummaryItem(String label, double amount, pw.Font ttf, pw.Font ttfBold, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(CurrencyFormatter.format(amount), style: pw.TextStyle(font: ttfBold, fontSize: 12, color: color)),
      ]
    );
  }
}
