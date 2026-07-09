import 'dart:convert';
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
}
