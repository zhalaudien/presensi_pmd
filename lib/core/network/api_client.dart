import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/preferences_helper.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio dio;
  final PreferencesHelper prefs;

  ApiClient({required this.prefs}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Auth & Retry Interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Auto-retry once on connection timeout or network glitch
          final requestOptions = error.requestOptions;
          final retryCount = (requestOptions.extra['retry_count'] as int? ?? 0);

          final isTimeoutOrNetwork =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.error is SocketException;

          if (isTimeoutOrNetwork && retryCount < 2) {
            requestOptions.extra['retry_count'] = retryCount + 1;
            await Future.delayed(const Duration(milliseconds: 1000));
            try {
              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  ApiException handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Koneksi ke server timeout (respons server lambat). Coba beberapa saat lagi atau gunakan mode offline.',
        statusCode: 408,
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau lanjutkan dalam mode offline.',
        statusCode: 0,
      );
    }

    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;

      String message = 'Terjadi kesalahan pada server ($statusCode)';
      Map<String, dynamic>? errors;

      if (data is Map<String, dynamic>) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();
        }

        if (data['errors'] is Map<String, dynamic>) {
          errors = data['errors'] as Map<String, dynamic>;
          final firstErrorKey = errors.keys.firstOrNull;
          if (firstErrorKey != null) {
            final firstErrorVal = errors[firstErrorKey];
            if (firstErrorVal is List && firstErrorVal.isNotEmpty) {
              message = firstErrorVal.first.toString();
            }
          }
        }
      }

      if (statusCode == 401) {
        prefs.clearSession();
        return ApiException(
          message: 'Sesi login telah berakhir atau kredensial salah.',
          statusCode: 401,
        );
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        errors: errors,
      );
    }

    return ApiException(
      message: e.message ?? 'Terjadi kesalahan yang tidak diketahui.',
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
