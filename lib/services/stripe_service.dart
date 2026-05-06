import 'dart:convert';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();

  static void initialize() {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    Stripe.merchantIdentifier = 'merchant.com.oaya';
  }

  /// Call Supabase Edge Function to create a PaymentIntent
  static Future<String> createPaymentIntent({
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

    return data['clientSecret'] as String;
  }

  /// Initialize and present the Stripe payment sheet
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    String? customerName,
    String? customerEmail,
  }) async {
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
}
