import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();

  static bool _useMockPaymentSheet = false;

  @visibleForTesting
  static set useMockPaymentSheet(bool value) {
    _useMockPaymentSheet = value;
  }

  static bool get _isMockEnabled => _useMockPaymentSheet && kDebugMode;

  static void initialize() {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    Stripe.merchantIdentifier = 'merchant.com.oaya';
  }

  /// Call Supabase Edge Function to create a PaymentIntent
  /// Returns both clientSecret and paymentIntentId.
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'eur',
  }) async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/create-payment-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
      },
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['clientSecret'] == null) {
      throw Exception(
        data['error'] ?? 'Impossible d\'initialiser le paiement.',
      );
    }

    return {
      'clientSecret': data['clientSecret'] as String,
      'paymentIntentId': data['paymentIntentId'] as String,
    };
  }

  /// Initialize and present the Stripe payment sheet
  static Future<bool> presentPaymentSheet({
    required BuildContext context,
    required String clientSecret,
    String? customerName,
    String? customerEmail,
  }) async {
    if (_isMockEnabled) {
      return _presentMockPaymentSheet(context);
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'OAYA Store',
        paymentIntentClientSecret: clientSecret,
        billingDetails: BillingDetails(
          name: customerName,
          email: customerEmail,
        ),
        appearance: PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: const Color(0xFF111111),
            background: const Color(0xFFFFFFFF),
            componentBackground: const Color(0xFFFAFAFA),
            primaryText: const Color(0xFF111111),
            secondaryText: const Color(0xFF6B6B6B),
            componentText: const Color(0xFF111111),
            placeholderText: const Color(0xFFACACAC),
            icon: const Color(0xFF6B6B6B),
          ),
          shapes: const PaymentSheetShape(
            borderRadius: 12,
            borderWidth: 1.5,
          ),
          primaryButton: PaymentSheetPrimaryButtonAppearance(
            colors: PaymentSheetPrimaryButtonTheme(
              light: PaymentSheetPrimaryButtonThemeColors(
                background: const Color(0xFF111111),
                text: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return true;
  }

  static Future<bool> _presentMockPaymentSheet(BuildContext context) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => const _MockPaymentSheet(),
        ) ??
        false;
  }
}

class _MockPaymentSheet extends StatefulWidget {
  const _MockPaymentSheet();

  @override
  State<_MockPaymentSheet> createState() => _MockPaymentSheetState();
}

class _MockPaymentSheetState extends State<_MockPaymentSheet> {
  static const _cardNumberKey = Key('stripe_card_number_field');
  static const _cardExpiryKey = Key('stripe_card_expiry_field');
  static const _cardCvcKey = Key('stripe_card_cvc_field');
  static const _cardPayKey = Key('stripe_card_pay_button');
  static const _cardMethodKey = Key('stripe_card_method_option');

  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvcCtrl = TextEditingController();
  String _method = 'card';

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TEST MODE',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              RadioListTile<String>(
                key: _cardMethodKey,
                value: 'card',
                groupValue: _method,
                title: const Text('Card'),
                onChanged: (value) => setState(() => _method = value ?? 'card'),
              ),
              if (_method == 'card') ...[
                TextField(
                  key: _cardNumberKey,
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Card number',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: _cardExpiryKey,
                        controller: _cardExpiryCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Expiry',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: _cardCvcKey,
                        controller: _cardCvcCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CVC',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: _cardPayKey,
                  onPressed: () {
                    if (_cardNumberCtrl.text.trim().isEmpty ||
                        _cardExpiryCtrl.text.trim().isEmpty ||
                        _cardCvcCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Pay €249.00'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
