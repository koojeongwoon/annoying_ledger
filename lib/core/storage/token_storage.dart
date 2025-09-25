import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:annoying_ledger/features/auth/models/token_bundle.dart';

class TokenStorage {
  TokenStorage(this._preferences);

  final SharedPreferences _preferences;

  static const _key = 'auth_tokens';

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  Future<void> save(TokenBundle tokens) async {
    await _preferences.setString(_key, jsonEncode(tokens.toJson()));
  }

  TokenBundle? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return TokenBundle.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
