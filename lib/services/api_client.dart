import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shoefit/config/app_environment.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? AppEnvironment.apiBaseUrl).replaceAll(
        RegExp(r'/$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _request('GET', path, queryParameters: queryParameters);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request('POST', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request('PUT', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) {
    return _request('DELETE', path, queryParameters: queryParameters);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';

    if (body != null) {
      request.body = jsonEncode(body);
    }

    // ignore: avoid_print
    print('API URL: $uri');

    try {
      final streamed = await _client.send(request).timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed);
      // ignore: avoid_print
      print('Status Code: ${response.statusCode}');
      // ignore: avoid_print
      print('Response Body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_buildHttpErrorMessage(response, uri));
      }

      if (response.body.isEmpty) {
        return null;
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.contains('application/json')) {
        throw Exception(
          'The API at $uri returned an unexpected ${response.headers['content-type'] ?? 'response type'}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);
        if (data['success'] == false) {
          throw Exception(_readApiMessage(data) ?? 'The API request failed.');
        }
        return data;
      }

      return decoded;
    } on http.ClientException catch (error) {
      throw Exception(
        'Cannot reach the API at $_baseUrl. Check that the server is reachable. $error',
      );
    } on TimeoutException {
      throw Exception(
        'The API at $_baseUrl took too long to respond. Please try again.',
      );
    } on FormatException {
      throw Exception('The API at $_baseUrl returned invalid JSON.');
    }
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final normalizedQueryParameters = queryParameters?.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, '${entry.value}'));
    return uri.replace(
      queryParameters: normalizedQueryParameters == null
          ? null
          : Map<String, String>.fromEntries(normalizedQueryParameters),
    );
  }

  String _buildHttpErrorMessage(http.Response response, Uri uri) {
    final statusMessage =
        'API request failed with HTTP ${response.statusCode} at $uri.';
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final responsePreview = _extractResponsePreview(response.body);

    if (contentType.contains('application/json')) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = _readApiMessage(decoded);
          if (message != null && message.isNotEmpty) {
            return '$statusMessage $message';
          }
        }
      } on FormatException {
        return '$statusMessage The server returned malformed JSON.';
      }
    }

    if (responsePreview != null) {
      return '$statusMessage Server response: $responsePreview';
    }

    return statusMessage;
  }

  String? _readApiMessage(Map<String, dynamic> data) {
    final message = data['message']?.toString().trim();
    if (message == null || message.isEmpty) {
      return null;
    }
    return message;
  }

  String? _extractResponsePreview(String body) {
    final plainText = body
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (plainText.isEmpty) {
      return null;
    }

    if (plainText.length <= 120) {
      return plainText;
    }

    return '${plainText.substring(0, 120)}...';
  }
}
