import 'dart:async';

import 'package:annoying_ledger/core/api/api_client.dart';
import 'package:annoying_ledger/core/storage/token_storage.dart';
import 'package:annoying_ledger/features/auth/models/auth_failures.dart';
import 'package:annoying_ledger/features/auth/models/token_bundle.dart';

class TokenAuthInterceptor implements ApiAuthInterceptor {
  TokenAuthInterceptor({
    required this.tokenStorage,
    required this.onRefresh,
    required this.onSessionExpired,
  });

  final TokenStorage tokenStorage;
  final Future<TokenBundle> Function(String refreshToken) onRefresh;
  final Future<void> Function() onSessionExpired;

  TokenBundle? _cachedTokens;
  Future<TokenBundle>? _refreshing;

  void setTokens(TokenBundle? tokens) {
    _cachedTokens = tokens;
  }

  void clearCache() {
    _cachedTokens = null;
  }

  TokenBundle? get cachedTokens => _cachedTokens;

  @override
  Future<Map<String, String>> onRequest() async {
    final tokens = await _ensureValidTokens();
    final prefix = tokens.tokenType.isEmpty ? 'Bearer' : tokens.tokenType;
    return {'Authorization': '$prefix ${tokens.accessToken}'};
  }

  @override
  Future<bool> onUnauthorized(ApiException error) async {
    final current = await _currentTokens();
    if (current == null) {
      return false;
    }
    if (current.isRefreshTokenExpired) {
      await _handleSessionExpiry();
      return false;
    }

    try {
      await _refresh(current, force: true);
      return true;
    } on SessionExpiredException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<TokenBundle> _ensureValidTokens() async {
    final current = await _currentTokens();
    if (current == null) {
      throw const AuthRequiredException();
    }
    if (current.isRefreshTokenExpired) {
      await _handleSessionExpiry();
      throw const SessionExpiredException();
    }
    if (current.isAccessTokenExpired) {
      return _refresh(current);
    }
    return current;
  }

  Future<TokenBundle?> _currentTokens() async {
    if (_cachedTokens != null) {
      return _cachedTokens;
    }
    final stored = await tokenStorage.read();
    _cachedTokens = stored;
    return stored;
  }

  Future<TokenBundle> _refresh(
    TokenBundle current, {
    bool force = false,
  }) async {
    if (_refreshing != null && !force) {
      return _refreshing!;
    }
    final future = onRefresh(current.refreshToken);
    _refreshing = future;
    try {
      final refreshed = await future;
      _cachedTokens = refreshed;
      return refreshed;
    } finally {
      if (_refreshing == future) {
        _refreshing = null;
      }
    }
  }

  Future<void> _handleSessionExpiry() async {
    _cachedTokens = null;
    await onSessionExpired();
  }
}
