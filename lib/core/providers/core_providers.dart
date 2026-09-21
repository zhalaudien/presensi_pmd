import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/preferences_helper.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/kegiatan/data/kegiatan_repository.dart';
import '../../features/presensi/data/presensi_repository.dart';

// Must be initialized in main()
final preferencesHelperProvider = Provider<PreferencesHelper>((ref) {
  throw UnimplementedError('preferencesHelperProvider must be overridden');
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(preferencesHelperProvider);
  return ApiClient(prefs: prefs);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(preferencesHelperProvider);
  return AuthRepository(apiClient: apiClient, prefs: prefs);
});

final kegiatanRepositoryProvider = Provider<KegiatanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return KegiatanRepository(
    apiClient: apiClient,
    connectivityService: connectivity,
  );
});

final presensiRepositoryProvider = Provider<PresensiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return PresensiRepository(
    apiClient: apiClient,
    connectivityService: connectivity,
  );
});
