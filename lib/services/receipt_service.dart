import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/theme.dart';
import '../utils/currency.dart';

class ReceiptService {
  ReceiptService._();

  static String buildReceiptText(Map<String, dynamic> order) {
    final buffer = StringBuffer();
    final orderId = _shortOrderId(order['id']);
    final createdAt = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final status = _statusLabel(order['status']?.toString());
    final paymentMethod = _paymentMethodLabel(order['payment_method']?.toString());
    final shipping = _toDouble(order['shipping']);
    final total = _toDouble(order['total_amount'] ?? order['total']);
    final items = (order['order_items'] as List? ?? const []);

    buffer.writeln('OAYA - Reçu de commande');
    buffer.writeln('Commande: #$orderId');
    if (createdAt != null) {
      buffer.writeln('Date: ${_formatDate(createdAt)}');
    }
    buffer.writeln('Statut: $status');
    buffer.writeln('Paiement: $paymentMethod');
    buffer.writeln('Livraison: ${shipping == 0 ? 'Gratuite' : formatCurrency(shipping)}');
    buffer.writeln('');
    buffer.writeln('Articles:');

    if (items.isEmpty) {
      buffer.writeln('- Aucun article disponible');
    } else {
      for (final rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        final product = item['product'] as Map<String, dynamic>? ?? const {};
        final name = product['name']?.toString() ?? 'Produit';
        final quantity = _toInt(item['quantity']) ?? 1;
        final unitPrice = _toDouble(item['unit_price']);
        buffer.writeln('- $name x$quantity (${formatCurrency(unitPrice * quantity)})');
      }
    }

    buffer.writeln('');
    buffer.writeln('Total: ${formatCurrency(total)}');
    return buffer.toString().trimRight();
  }

  static String buildShortSummary(Map<String, dynamic> order) {
    final orderId = _shortOrderId(order['id']);
    final total = _toDouble(order['total_amount'] ?? order['total']);
    final status = _statusLabel(order['status']?.toString());
    final paymentMethod = _paymentMethodLabel(order['payment_method']?.toString());
    return 'Commande #$orderId · $status · $paymentMethod · ${formatCurrency(total)}';
  }

  static Future<Uint8List> buildReceiptBytes(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final baseFont = pw.Font.ttf((await rootBundle.load('assets/fonts/WorkSans-Regular.ttf')).buffer.asByteData());
    final boldFont = pw.Font.ttf((await rootBundle.load('assets/fonts/WorkSans-SemiBold.ttf')).buffer.asByteData());
    final orderId = _shortOrderId(order['id']);
    final createdAt = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final status = _ascii(_statusLabel(order['status']?.toString()));
    final paymentMethod = _ascii(_paymentMethodLabel(order['payment_method']?.toString()));
    final shipping = _toDouble(order['shipping']);
    final total = _toDouble(order['total_amount'] ?? order['total']);
    final items = (order['order_items'] as List? ?? const []);

    // Convert Flutter colors to PDF colors
    final primaryColor = PdfColor.fromInt(AppColors.primary.value);
    final accentColor = PdfColor.fromInt(AppColors.accent.value);
    final secondaryTextColor = PdfColor.fromInt(AppColors.textSecondary.value);
    final borderColor = PdfColor.fromInt(AppColors.border.value);
    final backgroundColor = PdfColor.fromInt(AppColors.background.value);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(AppSpacing.xxl),
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(
              fontSize: AppFontSize.sm,
              color: primaryColor,
              font: baseFont,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with accent color
                pw.Text(
                  'OAYA',
                  style: pw.TextStyle(
                    fontSize: AppFontSize.xxxl,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    font: boldFont,
                  ),
                ),
                pw.SizedBox(height: AppSpacing.md),

                // Divider line
                pw.Divider(
                  color: borderColor,
                  height: AppSpacing.base,
                  thickness: 1,
                ),
                pw.SizedBox(height: AppSpacing.xl),

                // Receipt title
                pw.Text(
                  'Reçu de Commande',
                  style: pw.TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    font: boldFont,
                  ),
                ),
                pw.SizedBox(height: AppSpacing.xl),

                // Order details section
                _pdfDetailRow('Commande', '#$orderId', baseFont, boldFont, primaryColor, secondaryTextColor, AppSpacing.md),
                if (createdAt != null) _pdfDetailRow('Date', _ascii(_formatDate(createdAt)), baseFont, boldFont, primaryColor, secondaryTextColor, AppSpacing.md),
                _pdfDetailRow('Statut', status, baseFont, boldFont, primaryColor, secondaryTextColor, AppSpacing.md),
                _pdfDetailRow('Paiement', paymentMethod, baseFont, boldFont, primaryColor, secondaryTextColor, AppSpacing.md),
                _pdfDetailRow('Livraison', shipping == 0 ? 'Gratuite' : _ascii(formatCurrency(shipping)), baseFont, boldFont, primaryColor, secondaryTextColor, AppSpacing.md),

                pw.SizedBox(height: AppSpacing.xxl),

                // Items section header
                pw.Text(
                  'Articles',
                  style: pw.TextStyle(
                    fontSize: AppFontSize.lg,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    font: boldFont,
                  ),
                ),
                pw.SizedBox(height: AppSpacing.lg),

                // Items list
                if (items.isEmpty)
                  pw.Text(
                    'Aucun article disponible',
                    style: pw.TextStyle(
                      color: secondaryTextColor,
                      font: baseFont,
                    ),
                  )
                else
                  ...items.map((rawItem) {
                    final item = rawItem as Map<String, dynamic>;
                    final product = item['product'] as Map<String, dynamic>? ?? const {};
                    final name = _ascii(product['name']?.toString() ?? 'Produit');
                    final quantity = _toInt(item['quantity']) ?? 1;
                    final unitPrice = _toDouble(item['unit_price']);
                    final itemTotal = unitPrice * quantity;
                    return pw.Padding(
                      padding: pw.EdgeInsets.only(bottom: AppSpacing.base),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  name,
                                  style: pw.TextStyle(
                                    color: primaryColor,
                                    font: baseFont,
                                    fontSize: AppFontSize.sm,
                                  ),
                                ),
                              ),
                              pw.Text(
                                _ascii(formatCurrency(itemTotal)),
                                style: pw.TextStyle(
                                  color: primaryColor,
                                  font: boldFont,
                                  fontSize: AppFontSize.sm,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: AppSpacing.xs),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'x$quantity @ ${_ascii(formatCurrency(unitPrice))}',
                                style: pw.TextStyle(
                                  color: secondaryTextColor,
                                  font: baseFont,
                                  fontSize: AppFontSize.xs,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                pw.SizedBox(height: AppSpacing.xxl),

                // Total section with accent highlight
                pw.Divider(
                  color: borderColor,
                  height: AppSpacing.lg,
                  thickness: 1,
                ),
                pw.SizedBox(height: AppSpacing.lg),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: AppFontSize.lg,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        font: boldFont,
                      ),
                    ),
                    pw.Text(
                      _ascii(formatCurrency(total)),
                      style: pw.TextStyle(
                        fontSize: AppFontSize.lg,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                        font: boldFont,
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(
                  color: borderColor,
                  height: AppSpacing.lg,
                  thickness: 1,
                ),
                pw.SizedBox(height: AppSpacing.base),
                pw.Center(
                  child: pw.Text(
                    'Merci pour votre achat! · www.oaya.com',
                    style: pw.TextStyle(
                      fontSize: AppFontSize.xs,
                      color: secondaryTextColor,
                      font: baseFont,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static String buildReceiptFileName(Map<String, dynamic> order) {
    return 'oaya-recu-${_shortOrderId(order['id']).toLowerCase()}.pdf';
  }

  static String _shortOrderId(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length <= 8) return text.toUpperCase();
    return text.substring(0, 8).toUpperCase();
  }

  static String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'stripe':
        return 'Carte bancaire';
      case 'cod':
        return 'A la livraison';
      default:
        return method?.isNotEmpty == true ? method! : 'Non specifie';
    }
  }

  static String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En traitement';
      case 'shipped':
        return 'Expedie';
      case 'delivered':
        return 'Livre';
      case 'cancelled':
        return 'Annule';
      default:
        return status?.isNotEmpty == true ? status! : 'En attente';
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a ${hour}h$minute';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _ascii(String value) {
    return value
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u202F', ' ')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ù', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ô', 'O')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ç', 'C');
  }

  static pw.Widget _pdfDetailRow(
    String label,
    String value,
    pw.Font baseFont,
    pw.Font boldFont,
    PdfColor primaryColor,
    PdfColor secondaryColor,
    double spacing,
  ) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: spacing),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: secondaryColor,
              font: baseFont,
              fontSize: AppFontSize.sm,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: primaryColor,
              font: boldFont,
              fontSize: AppFontSize.sm,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value),
        ],
      ),
    );
  }
}