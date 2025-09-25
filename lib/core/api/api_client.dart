import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around [http.Client] that handles JSON encoding/decoding
/// and raises [ApiException] for non-success status codes.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _resolve(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final resolved = uri.replace(
      path: uri.path.endsWith('/')
          ? '${uri.path.substring(0, uri.path.length - 1)}$normalizedPath'
          : '${uri.path}$normalizedPath',
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
    return resolved;
  }

  Map<String, String> _mergeHeaders(
    Map<String, String>? headers, {
    bool includeJsonContentType = true,
  }) {
    return {
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _client.get(
      _resolve(path, query),
      headers: _mergeHeaders(headers, includeJsonContentType: false),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.post(
      _resolve(path),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.put(
      _resolve(path),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _client.delete(
      _resolve(path),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    return _handleResponse(response);
  }

  void close() => _client.close();

  Object? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return json.decode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return json.encode(body);
  }

  dynamic _handleResponse(http.Response response) {
    final data = _decodeBody(response);
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      return data;
    }
    throw ApiException(
      statusCode: code,
      message: 'Request failed with status $code',
      data: data,
    );
  }
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
  String toString() => 'ApiException($statusCode): $message';
}
