import 'package:flutter/foundation.dart';

import 'package:annoying_ledger/core/api/api_client.dart';
import 'package:annoying_ledger/features/auth/data/auth_repository.dart';
import 'package:annoying_ledger/features/auth/models/resource_access.dart';
import 'package:annoying_ledger/features/auth/models/auth_failures.dart';
import 'package:annoying_ledger/features/auth/models/token_bundle.dart';
import 'package:annoying_ledger/features/auth/models/user_profile.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initializing;
  TokenBundle? _tokens;
  UserProfile? _profile;
  UserResourceAccess? _resourceAccess;
  String? _errorMessage;
  bool _busy = false;
  bool _sessionExpired = false;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  List<MenuNode> get menuTree =>
      _resourceAccess?.buildMenuTree(onlyAccessible: true) ?? const [];
  List<ResourceAccessItem> get accessibleMenus =>
      _resourceAccess?.menus.where((menu) => menu.accessible).toList() ??
      const [];
  bool get isBusy => _busy || _status == AuthStatus.initializing;
  String? get errorMessage => _errorMessage;
  TokenBundle? get tokens => _tokens;
  bool get sessionExpired => _sessionExpired;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void acknowledgeSessionExpiry() {
    if (!_sessionExpired) return;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _status = AuthStatus.initializing;
    _sessionExpired = false;
    notifyListeners();
    final saved = await _repository.loadSavedTokens();
    if (saved == null) {
      _setUnauthenticated();
      return;
    }

    if (saved.isRefreshTokenExpired) {
      await _handleSessionExpired();
      notifyListeners();
      return;
    }

    _tokens = saved;
    await _loadAuthenticatedContext();
  }

  Future<void> login({
    required String email,
    required String password,
    String? clientId,
    String? deviceName,
    String? deviceFingerprint,
    String? scope,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    _sessionExpired = false;
    try {
      final tokens = await _repository.login(
        email: email,
        password: password,
        clientId: clientId,
        deviceName: deviceName,
        deviceFingerprint: deviceFingerprint,
        scope: scope,
      );
      _tokens = tokens;
      await _loadAuthenticatedContext();
    } on Exception catch (error) {
      _errorMessage = _toErrorMessage(error);
      _setUnauthenticated();
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    int? age,
  }) async {
    _setBusy(true);
    try {
      await _repository.register(
        email: email,
        password: password,
        name: name,
        age: age,
      );
      return null;
    } on Exception catch (error) {
      return _toErrorMessage(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout({String? reason}) async {
    final current = _tokens;
    if (current == null) {
      _setUnauthenticated();
      return;
    }
    _setBusy(true);
    _sessionExpired = false;
    try {
      await _repository.logout(tokens: current, reason: reason);
    } finally {
      _tokens = null;
      _profile = null;
      _resourceAccess = null;
      _setBusy(false);
      _setUnauthenticated();
    }
  }

  Future<void> refreshResources() async {
    if (!isAuthenticated) return;
    try {
      await _ensureFreshTokens();
      await _loadResources();
    } on SessionExpiredException catch (error) {
      await _handleSessionExpired(message: _toErrorMessage(error));
    } on AuthRequiredException catch (error) {
      await _handleSessionExpired(message: _toErrorMessage(error));
    } on Exception catch (error) {
      _errorMessage = _toErrorMessage(error);
    }
    notifyListeners();
  }

  Future<void> _loadAuthenticatedContext() async {
    try {
      await _ensureFreshTokens();
      await _loadProfile();
      await _loadResources();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _sessionExpired = false;
    } on SessionExpiredException catch (error) {
      await _handleSessionExpired(message: _toErrorMessage(error));
    } on AuthRequiredException catch (error) {
      await _handleSessionExpired(message: _toErrorMessage(error));
    } on Exception catch (error) {
      _errorMessage = _toErrorMessage(error);
      await _repository.clearTokens();
      _tokens = null;
      _profile = null;
      _resourceAccess = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final current = _tokens;
    if (current == null) {
      throw const AuthRequiredException();
    }
    _profile = await _repository.fetchCurrentUser();
    _syncTokensFromRepository();
  }

  Future<void> _loadResources() async {
    final current = _tokens;
    if (current == null) {
      throw const AuthRequiredException();
    }
    _resourceAccess = await _repository.fetchMyResources();
    _syncTokensFromRepository();
  }

  Future<void> _ensureFreshTokens() async {
    final latest = _repository.cachedTokens;
    final current = latest ?? _tokens;
    if (current == null) {
      throw const AuthRequiredException();
    }
    if (current.isRefreshTokenExpired) {
      throw const SessionExpiredException();
    }
    if (current.isAccessTokenExpired) {
      final refreshed = await _repository.refresh(
        refreshToken: current.refreshToken,
      );
      _tokens = refreshed;
    } else {
      _tokens = current;
    }
  }

  Future<void> _handleSessionExpired({String? message}) async {
    _sessionExpired = true;
    _errorMessage = message ?? '세션이 만료되었습니다. 다시 로그인해 주세요.';
    await _repository.clearTokens();
    _tokens = null;
    _profile = null;
    _resourceAccess = null;
    _status = AuthStatus.unauthenticated;
  }

  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _syncTokensFromRepository() {
    final latest = _repository.cachedTokens;
    if (latest != null) {
      _tokens = latest;
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  String _toErrorMessage(Exception error) {
    if (error is SessionExpiredException) {
      return '세션이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (error is AuthRequiredException) {
      return '인증이 필요합니다.';
    }
    if (error is ApiException) {
      final data = error.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return '요청이 실패했습니다. (코드: ${error.statusCode})';
    }
    if (error is FormatException) {
      return '응답을 파싱할 수 없습니다.';
    }
    return error.toString();
  }
}
