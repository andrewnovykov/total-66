import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
          ),
        ) {
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    } else {
      // Use browser-managed cookies in web runtime.
      try {
        final dynamic adapter = _dio.httpClientAdapter;
        adapter.withCredentials = true;
      } catch (_) {
        // No-op if adapter does not expose withCredentials.
      }
    }
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return _toMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response =
          await _dio.post(path, data: data, queryParameters: query);
      return _toMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: query);
      return _toMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response =
          await _dio.delete(path, data: data, queryParameters: query);
      return _toMap(response.data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = _toMap(error.response?.data);
    final message = _extractMessage(payload) ?? error.message ?? 'API request failed';

    return ApiException(
      message: message,
      statusCode: statusCode,
      payload: payload,
    );
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    final errorData = payload['error'];
    if (errorData is Map && errorData['message'] is String) {
      return errorData['message'] as String;
    }
    if (payload['message'] is String) {
      return payload['message'] as String;
    }
    return null;
  }
}
