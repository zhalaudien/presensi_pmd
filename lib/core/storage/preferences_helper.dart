import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyCabang = 'cabang_data';
  static const String _keyQuickChips = 'quick_chips';
  static const String _keyLastSync = 'last_sync_timestamp';

  final SharedPreferences _prefs;

  PreferencesHelper(this._prefs);

  static Future<PreferencesHelper> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesHelper(prefs);
  }

  // Token
  Future<bool> setToken(String token) => _prefs.setString(_keyToken, token);
  String? getToken() => _prefs.getString(_keyToken);
  bool hasToken() => _prefs.getString(_keyToken)?.isNotEmpty ?? false;
  Future<bool> removeToken() => _prefs.remove(_keyToken);

  // User
  Future<bool> setUser(Map<String, dynamic> userMap) =>
      _prefs.setString(_keyUser, jsonEncode(userMap));
  Map<String, dynamic>? getUser() {
    final str = _prefs.getString(_keyUser);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Cabang
  Future<bool> setCabang(Map<String, dynamic> cabangMap) =>
      _prefs.setString(_keyCabang, jsonEncode(cabangMap));
  Map<String, dynamic>? getCabang() {
    final str = _prefs.getString(_keyCabang);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Quick Chips
  Future<bool> setQuickChips(List<String> chips) =>
      _prefs.setStringList(_keyQuickChips, chips);
  List<String> getQuickChips() {
    final list = _prefs.getStringList(_keyQuickChips);
    if (list != null && list.isNotEmpty) return list;
    return [
      'Lembur / Shift Kerja',
      'Tugas Belajar / Kuliah',
      'Sedang di Luar Kota',
      'Acara Keluarga',
      'Kondisi Kurang Sehat / Sakit',
      'Urusan Mendesak',
    ];
  }

  // Last Sync
  Future<bool> setLastSync(DateTime time) =>
      _prefs.setString(_keyLastSync, time.toIso8601String());
  DateTime? getLastSync() {
    final str = _prefs.getString(_keyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // Clear all session
  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyCabang);
  }
}
