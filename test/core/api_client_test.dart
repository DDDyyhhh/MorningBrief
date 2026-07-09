import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';

void main() {
  test('ApiClient decodes JSON responses', () async {
    final client = ApiClient(MockClient((request) async {
      return http.Response(jsonEncode({'city': '上海'}), 200, headers: {'content-type': 'application/json'});
    }));

    expect(await client.getJson(Uri.parse('https://example.com')), {'city': '上海'});
  });

  test('ApiClient throws ApiClientException for non-200 responses', () async {
    final client = ApiClient(MockClient((request) async => http.Response('no', 500)));

    expect(client.getText(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });

  test('ApiClient wraps malformed JSON in ApiClientException', () async {
    final client = ApiClient(MockClient((request) async => http.Response('{bad json', 200)));

    expect(client.getJson(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });

  test('ApiClient throws ApiClientException when JSON is not an object', () async {
    final client = ApiClient(MockClient((request) async => http.Response('[1, 2, 3]', 200)));

    expect(client.getJson(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });

  test('ApiClient wraps client failures in ApiClientException', () async {
    final client = ApiClient(MockClient((request) async => throw http.ClientException('connection failed')));

    expect(client.getText(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });

  test('ApiClient wraps transport failures in ApiClientException', () async {
    final client = ApiClient(MockClient((request) async => throw const SocketException('network down')));

    expect(client.getText(Uri.parse('https://example.com')), throwsA(isA<ApiClientException>()));
  });
}
