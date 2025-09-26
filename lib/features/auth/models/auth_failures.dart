class AuthRequiredException implements Exception {
  const AuthRequiredException();

  @override
  String toString() => '인증이 필요합니다.';
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => '세션이 만료되었습니다.';
}
