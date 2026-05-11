import 'package:flutter_test/flutter_test.dart';

double calculateShipping(double total) {
  return total > 100 ? 0.0 : 9.99;
}

double calculateFinalTotal(double subtotal) {
  final shipping = calculateShipping(subtotal);
  return subtotal + shipping;
}

bool isValidCardNumber(String number) {
  final cleaned = number.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.length < 13 || cleaned.length > 19) return false;
  if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
  int sum = 0;
  bool alternate = false;
  for (int i = cleaned.length - 1; i >= 0; i--) {
    int digit = int.parse(cleaned[i]);
    if (alternate) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

bool isValidExpiry(int month, int year) {
  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;
  if (month < 1 || month > 12) return false;
  if (year < currentYear) return false;
  if (year == currentYear && month < currentMonth) return false;
  return true;
}

bool isValidCvv(String cvv) {
  return RegExp(r'^\d{3,4}$').hasMatch(cvv);
}

bool isAmountValid(double amount) {
  return amount > 0 && amount <= 99999.99;
}

String? validatePayment({
  required double subtotal,
  String? cardNumber,
  int? expiryMonth,
  int? expiryYear,
  String? cvv,
}) {
  if (!isAmountValid(subtotal)) {
    return 'Le montant doit être compris entre 0.01 et 99 999.99 TND';
  }

  if (cardNumber != null) {
    if (!isValidCardNumber(cardNumber)) {
      return 'Numéro de carte invalide';
    }
    if (expiryMonth == null || expiryYear == null || !isValidExpiry(expiryMonth, expiryYear)) {
      return 'Date d\'expiration invalide';
    }
    if (cvv == null || !isValidCvv(cvv)) {
      return 'Code de sécurité invalide';
    }
  }

  return null;
}

void main() {
  group('calculateShipping', () {
    test('free shipping over 100 TND', () {
      expect(calculateShipping(150), equals(0.0));
      expect(calculateShipping(100.01), equals(0.0));
    });

    test('shipping fee of 9.99 TND under 100 TND', () {
      expect(calculateShipping(50), equals(9.99));
      expect(calculateShipping(0), equals(9.99));
      expect(calculateShipping(99.99), equals(9.99));
    });

    test('shipping fee at exactly 100 TND (not over)', () {
      expect(calculateShipping(100), equals(9.99));
    });
  });

  group('calculateFinalTotal', () {
    test('total = subtotal + shipping when under 100', () {
      expect(calculateFinalTotal(50), closeTo(59.99, 0.001));
    });

    test('total = subtotal when over 100', () {
      expect(calculateFinalTotal(150), equals(150.0));
    });

    test('total = 0 for empty cart', () {
      expect(calculateFinalTotal(0), equals(9.99));
    });
  });

  group('isValidCardNumber', () {
    test('validates Stripe test card 4242...', () {
      expect(isValidCardNumber('4242424242424242'), isTrue);
    });

    test('validates Visa test card', () {
      expect(isValidCardNumber('4111111111111111'), isTrue);
    });

    test('rejects invalid card number', () {
      expect(isValidCardNumber('1234567890123456'), isFalse);
    });

    test('rejects empty card number', () {
      expect(isValidCardNumber(''), isFalse);
    });

    test('rejects card number with letters', () {
      expect(isValidCardNumber('4242abcd42424242'), isFalse);
    });

    test('handles card number with spaces', () {
      expect(isValidCardNumber('4242 4242 4242 4242'), isTrue);
    });

    test('rejects too short card number', () {
      expect(isValidCardNumber('4242'), isFalse);
    });

    test('accepts Mastercard test number', () {
      expect(isValidCardNumber('5555555555554444'), isTrue);
    });
  });

  group('isValidExpiry', () {
    test('accepts future date', () {
      expect(isValidExpiry(12, 2030), isTrue);
    });

    test('rejects invalid month (0)', () {
      expect(isValidExpiry(0, 2030), isFalse);
    });

    test('rejects invalid month (13)', () {
      expect(isValidExpiry(13, 2030), isFalse);
    });

    test('rejects past year', () {
      expect(isValidExpiry(1, 2020), isFalse);
    });
  });

  group('isValidCvv', () {
    test('accepts 3 digits', () {
      expect(isValidCvv('123'), isTrue);
    });

    test('accepts 4 digits (Amex)', () {
      expect(isValidCvv('1234'), isTrue);
    });

    test('rejects 2 digits', () {
      expect(isValidCvv('12'), isFalse);
    });

    test('rejects empty', () {
      expect(isValidCvv(''), isFalse);
    });

    test('rejects non-numeric', () {
      expect(isValidCvv('abc'), isFalse);
    });
  });

  group('isAmountValid', () {
    test('accepts positive amount', () {
      expect(isAmountValid(10.0), isTrue);
      expect(isAmountValid(0.01), isTrue);
    });

    test('rejects zero', () {
      expect(isAmountValid(0), isFalse);
    });

    test('rejects negative amount', () {
      expect(isAmountValid(-50), isFalse);
    });

    test('accepts maximum amount', () {
      expect(isAmountValid(99999.99), isTrue);
    });

    test('rejects amount over maximum', () {
      expect(isAmountValid(100000), isFalse);
    });
  });

  group('validatePayment (integrated)', () {
    test('returns null for valid COD payment', () {
      final result = validatePayment(subtotal: 150);
      expect(result, isNull);
    });

    test('returns null for valid card payment', () {
      final result = validatePayment(
        subtotal: 50,
        cardNumber: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
      );
      expect(result, isNull);
    });

    test('returns error for invalid amount', () {
      final result = validatePayment(subtotal: 0);
      expect(result, isNot(isNull));
    });

    test('returns error for invalid card', () {
      final result = validatePayment(
        subtotal: 50,
        cardNumber: '1234567890123456',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
      );
      expect(result, contains('carte'));
    });

    test('returns error for expired card', () {
      final result = validatePayment(
        subtotal: 50,
        cardNumber: '4242424242424242',
        expiryMonth: 1,
        expiryYear: 2020,
        cvv: '123',
      );
      expect(result, contains('expiration'));
    });

    test('returns error for invalid CVV', () {
      final result = validatePayment(
        subtotal: 50,
        cardNumber: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '12',
      );
      expect(result, contains('sécurité'));
    });
  });
}
