import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_shared/shared.dart';

void main() {
  test('offline and timeout failures have specific Indonesian messages', () {
    expect(
      authErrorMessage(TimeoutException('internal stack details')),
      'Permintaan terlalu lama. Silakan coba lagi.',
    );
    expect(
      authErrorMessage(
        DioException(
          requestOptions: RequestOptions(path: '/produk'),
          type: DioExceptionType.connectionError,
          message: 'Tidak ada koneksi internet',
        ),
      ),
      'Tidak ada koneksi internet',
    );
  });
}
