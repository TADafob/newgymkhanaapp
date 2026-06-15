import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Cardmanager/data/models/model2.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/providers/cardrechargeprovider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ViewReceiptPage extends ConsumerWidget {
  const ViewReceiptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/common/logo.png', height: 50), // Replace with actual logo
                  const SizedBox(height: 8),
                  Text(
                    'RECEIPT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('ID: ${receipt.receiptId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                receipt.companyName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Center(child: Text(receipt.address, textAlign: TextAlign.center,)),
            const SizedBox(height: 8),
            _buildRow('To:', receipt.customerName),
            _buildRow('Email:', receipt.email),
            _buildRow('Phone:', receipt.phone),
            const Divider(),
            _buildRow('Payment Method:', receipt.paymentMethod),
            _buildRow('Date + Time:', receipt.dateTime.toString()),
            const Divider(),
            _buildRow('Description', 'Amount'),
            _buildRow(receipt.meterNumber, 'Ksh ${receipt.amount}'),
            const SizedBox(height: 8),
            _buildRow('Subtotal', 'Ksh ${receipt.amount}'),
            const SizedBox(height: 16),
            _buildRow('Amount Paid', 'Ksh ${receipt.amount}'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _exportToPdf(context, receipt as Receipt),
              child: const Text('Export as PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

void _exportToPdf(BuildContext context, Receipt receipt) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('RECEIPT',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('ID: ${receipt.receiptId}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(receipt.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(receipt.address),
          pw.SizedBox(height: 8),
          _buildPdfRow('To:', receipt.customerName),
          _buildPdfRow('Email:', receipt.email),
          _buildPdfRow('Phone:', receipt.phone),
          pw.Divider(),
          _buildPdfRow('Payment Method:', receipt.paymentMethod),
          _buildPdfRow('Date + Time:', receipt.dateTime.toString()),
          pw.Divider(),
          _buildPdfRow('Description', 'Amount'),
          _buildPdfRow(receipt.meterNumber, 'GHS ${receipt.amount.toStringAsFixed(2)}'),
          pw.SizedBox(height: 8),
          _buildPdfRow('Subtotal', 'GHS ${receipt.amount.toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          _buildPdfRow('Amount Paid', 'GHS ${receipt.amount.toStringAsFixed(2)}'),
        ],
      ),
    ),
  );

  // Export PDF using Printing package
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}


pw.Widget _buildPdfRow(String title, String value) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text(value),
    ],
  );
}

}
