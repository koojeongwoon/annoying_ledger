import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'base_response.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<BaseResponse<T>> get<T>(
    String path,
    {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(Object? json)? fromJsonT,
  } ) async {
    return _sendRequest(
      'GET',
      path,
      query: query,
      headers: headers,
      fromJsonT: fromJsonT,
    );
  }

  Future<BaseResponse<T>> post<T>(
    String path,
    {
    Object? body,
    Map<String, String>? headers,
    T Function(Object? json)? fromJsonT,
  } ) async {
    return _sendRequest(
      'POST',
      path,
      body: body,
      headers: headers,
      fromJsonT: fromJsonT,
    );
  }

  Future<BaseResponse<T>> put<T>(
    String path,
    {
    Object? body,
    Map<String, String>? headers,
    T Function(Object? json)? fromJsonT,
  } ) async {
    return _sendRequest(
      'PUT',
      path,
      body: body,
      headers: headers,
      fromJsonT: fromJsonT,
    );
  }

  Future<BaseResponse<T>> delete<T>(
    String path,
    {
    Object? body,
    Map<String, String>? headers,
    T Function(Object? json)? fromJsonT,
  } ) async {
    return _sendRequest(
      'DELETE',
      path,
      body: body,
      headers: headers,
      fromJsonT: fromJsonT,
    );
  }

  Future<BaseResponse<T>> _sendRequest<T>(
    String method,
    String path,
    {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    T Function(Object? json)? fromJsonT,
  } ) async {
    final uri = _resolve(path, query);
    final mergedHeaders = _mergeHeaders(headers, includeJsonContentType: body != null);
    final encodedBody = _encodeBody(body);

    _logRequest(method, uri, mergedHeaders, encodedBody);

    final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: mergedHeaders);
          break;
        case 'POST':
          response = await _client.post(uri, headers: mergedHeaders, body: encodedBody);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: mergedHeaders, body: encodedBody);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: mergedHeaders, body: encodedBody);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      return _handleResponse(response, fromJsonT);
    } catch (e) {
      log('[$method] Request to $uri failed: $e', name: 'ApiClient');
      rethrow;
    }
  }

  BaseResponse<T> _handleResponse<T>(
      http.Response response, T Function(Object? json)? fromJsonT) {
    final responseBody = utf8.decode(response.bodyBytes);
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      final baseResponse = BaseResponse.fromJson(jsonResponse, fromJsonT);

      _logResponse(statusCode, responseBody, baseResponse);

      return baseResponse;
    } else {
      Object? data;
      try {
        data = json.decode(responseBody);
      } catch (_) {
        data = responseBody;
      }
      _logError(statusCode, responseBody);
      throw ApiException(
        statusCode: statusCode,
        message: 'Request failed with status $statusCode',
        data: data,
      );
    }
  }

  void _logRequest(String method, Uri uri, Map<String, String> headers, String? body) {
    final logMessage = '---\n' // Changed from '--- Request ---
        '[$method] $uri\n' // Changed from '[$method] $uri\n'
        'Headers: $headers';

    log(logMessage, name: 'ApiClient');
    if (body != null) {
      log('Body: $body', name: 'ApiClient');
    }
  }

  void _logResponse(int statusCode, String body, BaseResponse response) {
    final localTime = response.formattedLocalTimestamp;
    final logMessage = '---\n' // Changed from '--- Response ---
        'Status Code: $statusCode\n' // Changed from 'Status Code: $statusCode\n'
        'Server Time (UTC): ${response.timestamp}\n' // Changed from 'Server Time (UTC): ${response.timestamp}\n'
        'Client Time (Local): $localTime\n' // Changed from 'Client Time (Local): $localTime\n'
        'Body: $body';
    log(logMessage, name: 'ApiClient');
  }

  void _logError(int statusCode, String body) {
    final logMessage = '---\n' // Changed from '--- Error ---
        'Status Code: $statusCode\n' // Changed from 'Status Code: $statusCode\n'
        'Body: $body';
    log(logMessage, name: 'ApiClient', level: 900);
  }

  Uri _resolve(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return uri.replace(
      path: uri.path.endsWith('/')
          ? '${uri.path.substring(0, uri.path.length - 1)}$normalizedPath'
          : '${uri.path}$normalizedPath',
      queryParameters: query?.map((key, value) => MapEntry(key, value?.toString())),
    );
  }

  Map<String, String> _mergeHeaders(
    Map<String, String>? headers,
    {
    bool includeJsonContentType = true,
  } ) {
    return {
      if (includeJsonContentType) 'Content-Type': 'application/json; charset=UTF-8',
      if (headers != null) ...headers,
    };
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return json.encode(body);
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int statusCode;
  final String message;
  final Object? data;

  @override
  String toString() => 'ApiException($statusCode): $message\nData: $data';
}