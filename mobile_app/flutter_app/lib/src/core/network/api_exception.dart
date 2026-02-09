class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.payload,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? payload;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$code: $message';
  }
}
