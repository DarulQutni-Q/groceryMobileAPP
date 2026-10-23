import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

const sellerLoadLimit = Duration(seconds: 15);

bool _connected(List<ConnectivityResult> values) =>
    values.any((value) => value != ConnectivityResult.none);

final connectionCheckProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => _connected(await Connectivity().checkConnectivity()),
);
final connectionEventsProvider = Provider<Stream<bool>>(
  (ref) => Connectivity().onConnectivityChanged.map(_connected).distinct(),
);
final connectionStateProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final check = ref.watch(connectionCheckProvider);
  final changes = ref.watch(connectionEventsProvider);
  bool initial = true;
  try {
    initial = await check().timeout(sellerLoadLimit);
  } on TimeoutException {
    initial = true;
  }
  yield initial;
  yield* changes;
});

void configureSellerNetwork(ApiClient client, Future<bool> Function() check) {
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final generation =
            options.extra['sessionGeneration'] ?? client.storage.generation;
        try {
          bool online;
          try {
            online = await check().timeout(sellerLoadLimit);
          } on TimeoutException {
            // Jika connectivity check timeout (misal di HP fisik atau tunnel),
            // jangan langsung gagalkan request HTTP; biarkan transport Dio mencoba.
            online = true;
          }
          if (generation != client.storage.generation) {
            throw DioException(
              requestOptions: options,
              message: 'Sesi sudah berubah. Silakan coba lagi.',
            );
          }
          if (!online) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              message: 'Tidak ada koneksi internet',
            );
          }
          if (options.method == 'GET') {
            options.connectTimeout = sellerLoadLimit;
            options.receiveTimeout = sellerLoadLimit;
          }
          handler.next(options);
        } catch (error, stack) {
          handler.reject(
            error is DioException
                ? error
                : DioException(
                    requestOptions: options,
                    error: error,
                    stackTrace: stack,
                    type: DioExceptionType.connectionError,
                    message: 'Koneksi belum dapat diperiksa. Coba lagi.',
                  ),
          );
        }
      },
    ),
  );
}
