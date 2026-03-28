import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();

  factory SessionService() => _instance;

  SessionService._internal();

  static const String _sessionKey = 'app_session_count';

  Future<void> incrementSession() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_sessionKey) ?? 0;
    await prefs.setInt(_sessionKey, count + 1);
  }

  Future<int> getSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionKey) ?? 1;
  }
}
