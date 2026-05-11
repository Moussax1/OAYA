import 'package:flutter_test/flutter_test.dart';
import 'package:oaya_flutter/providers/providers.dart' as providers;

void main() {
  test('CartState totalPrice computes correctly', () {
    final items = [
      {
        'product': {'id': 'p1', 'price': 10.0},
        'quantity': 2,
      },
      {
        'product': {'id': 'p2', 'price': 5.5},
        'quantity': 3,
      },
    ];

    final state = providers.CartState(items: List<Map<String, dynamic>>.from(items));
    expect(state.totalItems, 5);
    expect(state.totalPrice, closeTo(10.0 * 2 + 5.5 * 3, 0.001));
  });
}
