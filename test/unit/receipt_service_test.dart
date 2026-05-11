import 'package:flutter_test/flutter_test.dart';
import 'package:oaya_flutter/services/receipt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptService', () {
    test('buildReceiptText includes order details and items', () async {
      final order = <String, dynamic>{
        'id': '12345678-abcdef',
        'created_at': '2026-05-10T14:30:00.000Z',
        'status': 'processing',
        'payment_method': 'stripe',
        'shipping': 9.99,
        'total_amount': 59.98,
        'order_items': [
          {
            'quantity': 2,
            'unit_price': 25.0,
            'product': {'name': 'T-shirt'},
          },
        ],
      };

      final receipt = ReceiptService.buildReceiptText(order);

      expect(receipt, contains('Commande: #12345678'));
      expect(receipt, contains('Statut: En traitement'));
      expect(receipt, contains('Paiement: Carte bancaire'));
      expect(receipt, contains('T-shirt x2'));
      expect(receipt, contains('Total:'));
      expect(ReceiptService.buildReceiptFileName(order), equals('oaya-recu-12345678.pdf'));
      final bytes = await ReceiptService.buildReceiptBytes(order);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('buildShortSummary is compact and readable', () {
      final order = <String, dynamic>{
        'id': 'abcd1234ffff',
        'status': 'pending',
        'payment_method': 'cod',
        'total_amount': 42.5,
      };

      final summary = ReceiptService.buildShortSummary(order);

      expect(summary, contains('Commande #ABCD1234'));
      expect(summary, contains('En attente'));
      expect(summary, contains('A la livraison'));
      expect(summary, contains('42'));
    });
  });
}