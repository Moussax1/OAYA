import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<void> main() async {
  await dotenv.load(fileName: 'assets/.env');
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  print('URL: $url');
  if (url.isEmpty || anonKey.isEmpty) {
    print('Missing keys');
    exit(1);
  }
  
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
  
  final client = Supabase.instance.client;
  
  try {
    print('Testing connection to products table...');
    final data = await client.from('products').select().limit(1);
    print('Success! Data: $data');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
