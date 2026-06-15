import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';

bool _isCredit(String? type) => (type ?? '').toLowerCase() == 'top up';

class StatementPdfGenerator {
  static Future<Uint8List> generate({
    required Profile profile,
    required List<Map<String, dynamic>> transactions,
    required DateTime from,
    required DateTime to,
    required double currentBalance,
  }) async {
    debugPrint('[StatementPdfGenerator] Starting PDF generation');
    debugPrint(
      '[StatementPdfGenerator] Profile: username="${profile.username}", email="${profile.email}", phone="${profile.phone}"',
    );
    debugPrint(
      '[StatementPdfGenerator] Transactions count: ${transactions.length}',
    );
    debugPrint(
      '[StatementPdfGenerator] Date range: ${DateFormat('dd MMM yyyy').format(from)} to ${DateFormat('dd MMM yyyy').format(to)}',
    );
    debugPrint('[StatementPdfGenerator] Current balance: $currentBalance');

    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('h:mm a');

    // Load logo
    final logoData = await rootBundle.load('assets/images/common/logo3.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Compute totals
    double totalCredit = 0;
    double totalDebit = 0;
    for (final tx in transactions) {
      try {
        final amtValue = tx['trans_Amount'];
        final amt = amtValue != null ? (amtValue as num).toDouble() : 0.0;
        debugPrint(
          '[StatementPdfGenerator] Transaction: Amount=$amt, Type=${tx['trans_Type']}, isCredit=${_isCredit(tx['trans_Type']?.toString())}',
        );
        if (_isCredit(tx['trans_Type']?.toString())) {
          totalCredit += amt;
        } else {
          totalDebit += amt;
        }
      } catch (e) {
        debugPrint(
          '[StatementPdfGenerator] ERROR processing transaction: $e, tx=$tx',
        );
        // Skip invalid transaction entries
        continue;
      }
    }
    debugPrint(
      '[StatementPdfGenerator] Totals - Credit: $totalCredit, Debit: $totalDebit',
    );

    // Colors
    const headerBg = PdfColor.fromInt(0xFF0A1628);
    const accentBlue = PdfColor.fromInt(0xFF0693e3);
    const creditGreen = PdfColor.fromInt(0xFF00C853);
    const debitRed = PdfColor.fromInt(0xFFFF5252);
    const lightGrey = PdfColor.fromInt(0xFFF5F7FA);
    const borderGrey = PdfColor.fromInt(0xFFE2E8F0);
    const textPrimary = PdfColor.fromInt(0xFF1A202C);
    const textSecondary = PdfColor.fromInt(0xFF718096);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          // ── Header ──────────────────────────────────────────────────
          pw.Container(
            color: headerBg,
            padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 64,
                  height: 64,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NAIROBI GYMKHANA',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Member Card Statement',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF90CDF4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xFF90CDF4),
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      dateFmt.format(DateTime.now()),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Blue accent bar ──────────────────────────────────────────
          pw.Container(height: 4, color: accentBlue),

          pw.SizedBox(height: 20),

          // ── Member Info + Period ─────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Member info
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: borderGrey),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MEMBER DETAILS',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        _pdfInfoRow(
                          'Name',
                          profile.username,
                          textPrimary,
                          textSecondary,
                        ),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow(
                          'Email',
                          profile.email,
                          textPrimary,
                          textSecondary,
                        ),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow(
                          'Phone',
                          profile.phone,
                          textPrimary,
                          textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                // Statement period + balance
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: lightGrey,
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: borderGrey),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'STATEMENT PERIOD',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            _pdfInfoRow(
                              'From',
                              dateFmt.format(from),
                              textPrimary,
                              textSecondary,
                            ),
                            pw.SizedBox(height: 4),
                            _pdfInfoRow(
                              'To',
                              dateFmt.format(to),
                              textPrimary,
                              textSecondary,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Current balance box
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(14),
                        decoration: pw.BoxDecoration(
                          color: headerBg,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'CURRENT BALANCE',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColor.fromInt(0xFF90CDF4),
                                letterSpacing: 1.2,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'KES ${fmt.format(currentBalance)}',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Summary Cards ────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Row(
              children: [
                _summaryCard(
                  'TOTAL CREDITS',
                  'KES ${fmt.format(totalCredit)}',
                  creditGreen,
                  transactions
                      .where((t) => _isCredit(t['trans_Type']?.toString()))
                      .length,
                ),
                pw.SizedBox(width: 12),
                _summaryCard(
                  'TOTAL DEBITS',
                  'KES ${fmt.format(totalDebit)}',
                  debitRed,
                  transactions
                      .where((t) => !_isCredit(t['trans_Type']?.toString()))
                      .length,
                ),
                pw.SizedBox(width: 12),
                _summaryCard(
                  'TOTAL TRANSACTIONS',
                  transactions.length.toString(),
                  accentBlue,
                  null,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ── Transactions Table ───────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TRANSACTION HISTORY',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Table header
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: headerBg,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(8),
                      topRight: const pw.Radius.circular(8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: _tableHeaderCell('DATE & TIME'),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: _tableHeaderCell('RECEIPT NO.'),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: _tableHeaderCell('DESCRIPTION'),
                      ),
                      pw.Expanded(flex: 1, child: _tableHeaderCell('TYPE')),
                      pw.Expanded(
                        flex: 2,
                        child: _tableHeaderCell('AMOUNT', alignRight: true),
                      ),
                    ],
                  ),
                ),
                // Table rows
                if (transactions.isEmpty)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderGrey),
                      borderRadius: pw.BorderRadius.only(
                        bottomLeft: const pw.Radius.circular(8),
                        bottomRight: const pw.Radius.circular(8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Center(
                      child: pw.Text(
                        'No transactions found for this period.',
                        style: pw.TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                else
                  ...transactions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    debugPrint(
                      '[StatementPdfGenerator] Processing transaction $i: $tx',
                    );

                    final isLast = i == transactions.length - 1;
                    final credit = _isCredit(tx['trans_Type']?.toString());

                    // Safely extract amount
                    double amt = 0.0;
                    try {
                      final amtValue = tx['trans_Amount'];
                      if (amtValue != null) {
                        amt = (amtValue as num).toDouble();
                      }
                      debugPrint(
                        '[StatementPdfGenerator] Transaction $i amount: $amt',
                      );
                    } catch (e) {
                      debugPrint(
                        '[StatementPdfGenerator] ERROR extracting amount in transaction $i: $e',
                      );
                      amt = 0.0;
                    }

                    // Safely extract date
                    DateTime ts = DateTime.now();
                    try {
                      final dateValue = tx['trans_Date'];
                      debugPrint(
                        '[StatementPdfGenerator] Transaction $i dateValue type: ${dateValue.runtimeType}, value: $dateValue',
                      );
                      if (dateValue is Timestamp) {
                        ts = dateValue.toDate();
                      } else if (dateValue is DateTime) {
                        ts = dateValue;
                      }
                      debugPrint(
                        '[StatementPdfGenerator] Transaction $i extracted date: $ts',
                      );
                    } catch (e) {
                      debugPrint(
                        '[StatementPdfGenerator] ERROR extracting date in transaction $i: $e',
                      );
                      ts = DateTime.now();
                    }

                    final rawDescr =
                        (tx['trans_Descr']?.toString() ?? '').trim();
                    final waiter = (tx['waiter']?.toString() ?? '').trim();
                    final item = (tx['item']?.toString() ?? '').trim();
                    final payMethod =
                        (tx['payment_method']?.toString() ?? '').trim();
                    final rcpt = (tx['rcpt_no']?.toString() ??
                            tx['trans_Id']?.toString() ??
                            '')
                        .trim();

                    // Build a rich description line
                    final descrParts = <String>[];
                    if (rawDescr.isNotEmpty) descrParts.add(rawDescr);
                    if (item.isNotEmpty) descrParts.add(item);
                    if (waiter.isNotEmpty) descrParts.add('Waiter: $waiter');
                    if (payMethod.isNotEmpty) descrParts.add(payMethod);
                    final descr = descrParts.isNotEmpty
                        ? descrParts.join(' · ')
                        : (credit ? 'Card Top Up' : 'Payment');
                    final isEven = i % 2 == 0;

                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : lightGrey,
                        border: pw.Border(
                          left: pw.BorderSide(color: borderGrey),
                          right: pw.BorderSide(color: borderGrey),
                          bottom: pw.BorderSide(color: borderGrey),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  dateFmt.format(ts),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                pw.Text(
                                  timeFmt.format(ts),
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              rcpt.isNotEmpty ? rcpt : '—',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              descr,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: textPrimary,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color: credit
                                    ? PdfColor.fromInt(0xFFE8F5E9)
                                    : PdfColor.fromInt(0xFFFFEBEE),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                credit ? 'CR' : 'DR',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: credit ? creditGreen : debitRed,
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${credit ? '+' : '-'} KES ${fmt.format(amt)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: credit ? creditGreen : debitRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                pw.SizedBox(height: 16),

                // Totals row
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderGrey),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Credits: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),
                      pw.Text(
                        'KES ${fmt.format(totalCredit)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: creditGreen,
                        ),
                      ),
                      pw.SizedBox(width: 24),
                      pw.Text(
                        'Total Debits: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),
                      pw.Text(
                        'KES ${fmt.format(totalDebit)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: debitRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 32),

          // ── Disclaimer ───────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFFBEB),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFFDE68A)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DISCLAIMER',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF92400E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'This statement is generated for informational purposes only and reflects card transactions recorded in the Nairobi Gymkhana system within the selected period. '
                    'This document does not constitute an official financial statement. '
                    'Nairobi Gymkhana reserves the right to correct any errors or omissions. '
                    'For disputes or queries regarding any transaction, please contact the club administration at the earliest convenience. '
                    'This statement is confidential and intended solely for the named member.',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromInt(0xFF78350F),
                      lineSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Footer ───────────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Divider(color: borderGrey),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(32, 8, 32, 24),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '© ${DateTime.now().year} Nairobi Gymkhana. All rights reserved.',
                  style: pw.TextStyle(fontSize: 8, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    debugPrint('[StatementPdfGenerator] PDF generation completed, saving...');
    return pdf.save();
  }

  static pw.Widget _pdfInfoRow(
    String label,
    String value,
    PdfColor textPrimary,
    PdfColor textSecondary,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 48,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: textSecondary),
          ),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 9, color: textSecondary)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryCard(
    String label,
    String value,
    PdfColor color,
    int? count,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColor.fromInt(0xFF718096),
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            if (count != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                '$count transaction${count == 1 ? '' : 's'}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF718096),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {bool alignRight = false}) {
    return pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 0.8,
      ),
    );
  }
}
