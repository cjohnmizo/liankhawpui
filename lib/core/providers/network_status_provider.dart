import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !_isOffline(initial);

  await for (final result in connectivity.onConnectivityChanged) {
    yield !_isOffline(result);
  }
});

bool _isOffline(List<ConnectivityResult> values) {
  if (values.isEmpty) return true;
  return values.every((value) => value == ConnectivityResult.none);
}
