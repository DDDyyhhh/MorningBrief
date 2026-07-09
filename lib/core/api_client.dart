import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClientException implements Exception {
  ApiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

class ApiClient {
  ApiClient([http.Client? client, Duration? timeout])
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 12);

  final http.Client _client;
  final Duration _timeout;

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final text = await getText(uri);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiClientException('返回数据不是 JSON 对象');
  }

  Future<String> getText(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiClientException('请求失败', statusCode: response.statusCode);
      }
      return response.body;
    } on TimeoutException {
      throw ApiClientException('请求超时');
    }
  }
}
