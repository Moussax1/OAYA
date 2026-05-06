import 'package:intl/intl.dart';

String formatCurrency(dynamic amount) {
  final value = double.tryParse(amount.toString()) ?? 0.0;
  final formatter = NumberFormat.currency(
    locale: 'fr_TN',
    symbol: 'TND',
    decimalDigits: 2,
  );
  return formatter.format(value);
}
