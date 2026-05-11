import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PaymentMethodService {
  PaymentMethodService._();
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    final data = await _client
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> addPaymentMethod({
    required String userId,
    required String type,
    String? stripePaymentMethodId,
    String? lastFour,
    String? brand,
    bool isDefault = false,
  }) async {
    final data = await _client.from('payment_methods').insert({
      'user_id': userId,
      'type': type,
      'stripe_payment_method_id': stripePaymentMethodId,
      'last_four': lastFour,
      'brand': brand,
      'is_default': isDefault,
    }).select().single();
    return Map<String, dynamic>.from(data);
  }

  static Future<void> deletePaymentMethod(String paymentMethodId) async {
    await _client.from('payment_methods').delete().eq('id', paymentMethodId);
  }

  static Future<void> setDefault(String paymentMethodId, String userId) async {
    await _client.from('payment_methods').update({'is_default': false}).eq('user_id', userId).neq('id', paymentMethodId);
    await _client.from('payment_methods').update({'is_default': true}).eq('id', paymentMethodId);
  }
}
