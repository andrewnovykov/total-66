import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // Fallback is only used if .env is missing.
    return 'https://heads-up-docker.onrender.com';
  }
}
