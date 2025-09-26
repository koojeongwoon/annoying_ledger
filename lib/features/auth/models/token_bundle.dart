class TokenBundle {
  TokenBundle({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.sessionId,
  });

  final String tokenType;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String sessionId;

  factory TokenBundle.fromJson(Map<String, dynamic> json) {
    return TokenBundle(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String? ?? '',
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String? ?? '',
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ),
      sessionId: json['sessionId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenType': tokenType,
      'accessToken': accessToken,
      'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
      'sessionId': sessionId,
    };
  }

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiresAt);

  bool get isRefreshTokenExpired =>
      DateTime.now().isAfter(refreshTokenExpiresAt);

  TokenBundle copyWith({
    String? tokenType,
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
    String? sessionId,
  }) {
    return TokenBundle(
      tokenType: tokenType ?? this.tokenType,
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}
