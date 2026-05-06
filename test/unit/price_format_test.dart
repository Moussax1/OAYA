import 'package:flutter_test/flutter_test.dart';
import 'package:oaya_flutter/utils/currency.dart';

void main() {
  group('formatCurrency', () {
    test('formats 0 correctly', () {
      final res = formatCurrency(0).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
      expect(res, equals('0,00 TND'));
    });

    test('formats positive numbers correctly', () {
      final res = formatCurrency(1234.5).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
      expect(res, equals('1 234,50 TND'));
    });

    test('formats negative values correctly', () {
      final res = formatCurrency(-500.25).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
      expect(res, equals('-500,25 TND'));
    });

    test('formats large numbers correctly', () {
      final res = formatCurrency(1000000.99).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
      expect(res, equals('1 000 000,99 TND'));
    });
  });
}
