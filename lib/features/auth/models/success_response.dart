class SuccessResponse {
  SuccessResponse({
    this.code,
    this.message,
    this.data,
    this.timestamp,
  });

  final String? code;
  final String? message;
  final dynamic data;
  final DateTime? timestamp;

  factory SuccessResponse.fromJson(Map<String, dynamic> json) {
    return SuccessResponse(
      code: json['code'] as String?,
      message: json['message'] as String?,
      data: json['data'],
      timestamp: _parseDateTime(json['timestamp']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
