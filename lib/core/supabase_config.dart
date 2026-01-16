import 'app_config.dart';

class SupabaseConfig {
  static String get url => AppConfig.supabaseUrl;
  static String get anonKey => AppConfig.supabaseAnonKey;
}
