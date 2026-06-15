import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _deviceIdKey = 'device_id';
  static const String lastOpenedKey = "last_opened_notifications";
  static const String userIdKey = "uid";

  static Future<void> setLastOpenedTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastOpenedKey, time.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastOpenedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(lastOpenedKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
  }

  static Future<void> setDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

static const _notificationsEnabledKey = 'notifications_enabled';
  static const _onboardingKey = 'has_seen_onboarding';

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

// Save locally
static Future<void> setNotificationsEnabled(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_notificationsEnabledKey, enabled);
}

// Read locally; null = never asked
static Future<bool?> getNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_notificationsEnabledKey);
}

}