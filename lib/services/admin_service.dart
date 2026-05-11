import 'supabase_service.dart';

class AdminService {
  AdminService._();

  static const String userRole = 'user';
  static const String adminRole = 'admin';

  static Future<bool> isCurrentUserAdmin() async {
    final client = SupabaseService.client;
    try {
      final result = await client.rpc('is_admin');
      return result == true;
    } catch (_) {
      final user = client.auth.currentUser;
      if (user == null) return false;
      final profile = await client.from('profiles').select('role').eq('id', user.id).maybeSingle();
      final role = profile?['role'] as String?;
      return role == adminRole || role == 'owner';
    }
  }

  static Future<void> updateUserRole(String userId, String role) async {
    final client = SupabaseService.client;
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized');
    }
    await client.from('profiles').update({'role': role}).eq('id', userId);
  }

  static Future<void> promoteUser(String userId) => updateUserRole(userId, adminRole);

  static Future<void> demoteUser(String userId) => updateUserRole(userId, userRole);
}
