import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:annoying_ledger/features/auth/models/token_bundle.dart';

class TokenStorage {
  TokenStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _key = 'auth_tokens';

  static Future<TokenStorage> create() async {
    const storage = FlutterSecureStorage();
    return TokenStorage(storage);
  }

  Future<void> save(TokenBundle tokens) async {
    await _secureStorage.write(key: _key, value: jsonEncode(tokens.toJson()));
  }

  Future<TokenBundle?> read() async {
    final raw = await _secureStorage.read(key: _key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return TokenBundle.fromJson(data);
    } catch (_) {
      await _secureStorage.delete(key: _key);
      return null;
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _key);
  }
}
