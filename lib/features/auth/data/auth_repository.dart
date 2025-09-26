import 'package:annoying_ledger/core/api/api_client.dart';
import 'package:annoying_ledger/core/storage/token_storage.dart';
import 'package:annoying_ledger/features/auth/models/resource_access.dart';

import 'package:annoying_ledger/features/auth/models/token_bundle.dart';
import 'package:annoying_ledger/features/auth/models/user_profile.dart';

class AuthRepository {
  AuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  static const _loginPath = '/api/auth/login';
  static const _refreshPath = '/api/auth/refresh';
  static const _logoutPath = '/api/auth/logout';
  static const _profilePath = '/api/users/me';
  static const _resourcesPath = '/api/auth/resources/me';
  static const _registerPath = '/api/users/register';

  TokenBundle? loadSavedTokens() => tokenStorage.read();

  Future<void> clearTokens() => tokenStorage.clear();

  Future<TokenBundle> login({
    required String email,
    required String password,
    String? clientId,
    String? deviceName,
    String? deviceFingerprint,
    String? scope,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      if (clientId != null) 'clientId': clientId,
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
      if (scope != null) 'scope': scope,
    };

    final response = await apiClient.post(
      _loginPath,
      body: payload,
      fromJsonT: (json) => TokenBundle.fromJson(json as Map<String, dynamic>),
    );

    final tokens = response.data!;
    await tokenStorage.save(tokens);
    return tokens;
  }

  Future<TokenBundle> refresh({
    required String refreshToken,
    String? deviceFingerprint,
    String? scope,
  }) async {
    final payload = {
      'refreshToken': refreshToken,
      if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
      if (scope != null) 'scope': scope,
    };

    final response = await apiClient.post(
      _refreshPath,
      body: payload,
      fromJsonT: (json) => TokenBundle.fromJson(json as Map<String, dynamic>),
    );

    final tokens = response.data!;
    await tokenStorage.save(tokens);
    return tokens;
  }

  Future<void> logout({
    required TokenBundle tokens,
    String? reason,
  }) async {
    try {
      await apiClient.post(
        _logoutPath,
        body: {
          'sessionId': tokens.sessionId,
          if (reason != null) 'reason': reason,
        },
        headers: _authHeader(tokens.accessToken, tokens.tokenType),
      );
    } finally {
      await tokenStorage.clear();
    }
  }

  Future<UserProfile> fetchCurrentUser(TokenBundle tokens) async {
    final response = await apiClient.get(
      _profilePath,
      headers: _authHeader(tokens.accessToken, tokens.tokenType),
      fromJsonT: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<UserResourceAccess> fetchMyResources(TokenBundle tokens) async {
    final response = await apiClient.get(
      _resourcesPath,
      headers: _authHeader(tokens.accessToken, tokens.tokenType),
      fromJsonT: (json) => UserResourceAccess.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    int? age,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'name': name,
      if (age != null) 'age': age,
    };

    await apiClient.post(_registerPath, body: payload);
  }

  Map<String, String> _authHeader(String accessToken, String tokenType) {
    final prefix = tokenType.isEmpty ? 'Bearer' : tokenType;
    return {
      'Authorization': '$prefix $accessToken',
    };
  }
}