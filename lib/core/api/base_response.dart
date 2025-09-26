
import 'package:intl/intl.dart';

class BaseResponse<T> {
  final String code;
  final String message;
  final T? data;
  final DateTime timestamp;

  BaseResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(Object? json)? fromJsonT) {
    return BaseResponse<T>(
      code: json['code'] as String,
      message: json['message'] as String,
      data: json['data'] == null ? null : fromJsonT!(json['data']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  DateTime get localTimestamp => timestamp.toLocal();

  String get formattedLocalTimestamp {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(localTimestamp);
  }
}
