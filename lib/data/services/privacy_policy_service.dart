import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/data/models/privacy_policy.dart';

class PrivacyPolicyService {
  PrivacyPolicyService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _resourcePath = '/admin/privacy-policy';

  Uri _resolveUri([String pathSuffix = '']) {
    final buffer = StringBuffer(baseUrl);
    buffer.write(_resourcePath);
    if (pathSuffix.isNotEmpty) {
      if (!pathSuffix.startsWith('/')) {
        buffer.write('/');
      }
      buffer.write(pathSuffix);
    }
    return Uri.parse(buffer.toString());
  }

  Future<PrivacyPolicy?> fetchPrivacyPolicy() async {
    final response = await _client.get(
      _resolveUri(),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.isEmpty) {
        return null;
      }

      final String text = (data['text'] ?? '').toString();
      final String updatedAt = (data['updated_at'] ?? '').toString();

      if (text.trim().isEmpty && updatedAt.trim().isEmpty) {
        return null;
      }

      return PrivacyPolicy(
        id: _parseId(data['id']),
        text: text,
        updatedAt: _parseDate(updatedAt),
      );
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw HttpException(_errorMessage('fetch privacy policy', response));
  }

  Future<PrivacyPolicyMutationResult> createPrivacyPolicy(String text) async {
    final response = await _sendMultipart(
      method: 'POST',
      uri: _resolveUri(),
      fields: {'text': text},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final policy = PrivacyPolicy(
        id: _parseId(data['id']),
        text: (data['text'] ?? text).toString(),
        updatedAt: _parseDate(data['updated_at']),
      );
      return PrivacyPolicyMutationResult(
        policy: policy,
        success: _parseSuccess(data['success']),
        message: (data['message'] ?? '').toString().trim().isEmpty ? null : data['message'].toString(),
      );
    }

    throw HttpException(_errorMessage('create privacy policy', response));
  }

  Future<PrivacyPolicyMutationResult> updatePrivacyPolicy({
    required String text,
  }) async {
    final response = await _sendMultipart(
      method: 'POST',
      uri: _resolveUri(),
      fields: {'text': text},
      overrideMethod: 'PATCH',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final policy = PrivacyPolicy(
        id: _parseId(data['id']),
        text: (data['text'] ?? text).toString(),
        updatedAt: _parseDate(data['updated_at']),
      );
      return PrivacyPolicyMutationResult(
        policy: policy,
        success: _parseSuccess(data['success']),
        message: (data['message'] ?? '').toString().trim().isEmpty ? null : data['message'].toString(),
      );
    }

    if (response.statusCode == 404) {
      throw PrivacyPolicyNotFoundException(
        'No privacy policy exists yet. Please create one first.',
      );
    }

    throw HttpException(_errorMessage('update privacy policy', response));
  }

  Future<http.Response> _sendMultipart({
    required String method,
    required Uri uri,
    required Map<String, String> fields,
    String? overrideMethod,
  }) async {
    final request = http.MultipartRequest(method, uri)
      ..fields.addAll(fields);

    if (overrideMethod != null && overrideMethod.isNotEmpty) {
      request.fields['_method'] = overrideMethod;
    }

    request.headers['Accept'] = 'application/json';
    final streamedResponse = await _client.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  bool _parseSuccess(dynamic value) {
    if (value is bool) return value;
    if (value == null) return true;
    final lower = value.toString().toLowerCase();
    return lower == 'true' || lower == '1';
  }

  String _errorMessage(String action, http.Response response) {
    return 'Failed to $action. Status code: ${response.statusCode}. Body: ${response.body}';
  }

  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class PrivacyPolicyMutationResult {
  PrivacyPolicyMutationResult({
    required this.policy,
    required this.success,
    this.message,
  });

  final PrivacyPolicy policy;
  final bool success;
  final String? message;
}

class PrivacyPolicyNotFoundException extends HttpException {
  PrivacyPolicyNotFoundException(String message) : super(message);
}

class HttpException implements Exception {
  HttpException(this.message);
  final String message;

  @override
  String toString() => message;
}
