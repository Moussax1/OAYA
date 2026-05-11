import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AddressService {
  AddressService._();
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getAddresses(String userId) async {
    final data = await _client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> addAddress({
    required String userId,
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String postalCode,
    bool isDefault = false,
  }) async {
    final data = await _client.from('addresses').insert({
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
    }).select().single();
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    String? fullName,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (postalCode != null) body['postal_code'] = postalCode;
    if (isDefault != null) body['is_default'] = isDefault;
    final data = await _client.from('addresses').update(body).eq('id', addressId).select().single();
    return Map<String, dynamic>.from(data);
  }

  static Future<void> deleteAddress(String addressId) async {
    await _client.from('addresses').delete().eq('id', addressId);
  }

  static Future<Map<String, dynamic>?> getDefaultAddress(String userId) async {
    final data = await _client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();
    if (data != null) return Map<String, dynamic>.from(data);
    final first = await _client
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (first != null) return Map<String, dynamic>.from(first);
    return null;
  }
}
