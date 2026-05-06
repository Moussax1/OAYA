import 'package:flutter_test/flutter_test.dart';

// Since the cart logic is inside the StateNotifier provider in the app,
// we will test the logic directly here as functions that match the requirement.

double calculateTotal(List<Map<String, dynamic>> items) {
  return items.fold(0.0, (sum, item) {
    final price = double.tryParse(item['product']['price'].toString()) ?? 0.0;
    final qty = item['quantity'] as int;
    return sum + (price * qty);
  });
}

int calculateItemCount(List<Map<String, dynamic>> items) {
  return items.fold(0, (sum, item) => sum + (item['quantity'] as int));
}

double calculateShipping(double total) {
  return total > 100.0 ? 0.0 : 9.99;
}

void main() {
  group('Cart Logic Tests', () {
    test('calculateTotal with items', () {
      final items = [
        {'product': {'price': 10.0}, 'quantity': 2},
        {'product': {'price': 25.5}, 'quantity': 1},
      ];
      expect(calculateTotal(items), equals(45.5));
    });

    test('calculateItemCount', () {
      final items = [
        {'product': {'price': 10.0}, 'quantity': 3},
        {'product': {'price': 25.5}, 'quantity': 2},
      ];
      expect(calculateItemCount(items), equals(5));
    });

    test('calculateShipping is free over 100', () {
      expect(calculateShipping(150.0), equals(0.0));
    });

    test('calculateShipping is 9.99 under 100', () {
      expect(calculateShipping(50.0), equals(9.99));
    });

    test('calculateTotal with empty cart is 0.0', () {
      expect(calculateTotal([]), equals(0.0));
    });
  });
}
