import 'package:presensi_pmd/core/constants/api_endpoints.dart';
import 'package:presensi_pmd/core/network/api_client.dart';
import 'package:presensi_pmd/core/network/connectivity_service.dart';
import 'package:presensi_pmd/core/storage/database_helper.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';

class KegiatanRepository {
  final ApiClient apiClient;
  final ConnectivityService connectivityService;

  KegiatanRepository({
    required this.apiClient,
    required this.connectivityService,
  });

  Future<List<KegiatanModel>> getKegiatanList({int? cabangId, bool forceRefresh = false}) async {
    final isOnline = await connectivityService.checkOnline();

    if (isOnline && (forceRefresh || true)) {
      try {
        final response = await apiClient.get(ApiEndpoints.kegiatan);
        final resData = response.data;
        if (resData != null && resData['data'] is List) {
          final listRaw = (resData['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();

          // Cache in SQLite
          await DatabaseHelper.cacheKegiatanList(listRaw);

          return listRaw.map((e) => KegiatanModel.fromJson(e)).toList();
        }
      } catch (e) {
        // Fallback to local cache if network call fails
      }
    }

    // Load from local SQLite cache
    final localData = await DatabaseHelper.getCachedKegiatanList(cabangId: cabangId);
    return localData.map((e) => KegiatanModel.fromJson(e)).toList();
  }

  Future<KegiatanModel> getKegiatanDetail(int id) async {
    final isOnline = await connectivityService.checkOnline();
    if (isOnline) {
      try {
        final response = await apiClient.get(ApiEndpoints.kegiatanDetail(id));
        final resData = response.data;
        if (resData != null && resData['data'] is Map<String, dynamic>) {
          final data = resData['data'] as Map<String, dynamic>;
          await DatabaseHelper.cacheSingleKegiatan(data);
          return KegiatanModel.fromJson(data);
        }
      } catch (_) {}
    }

    final cached = await DatabaseHelper.getCachedKegiatanById(id);
    if (cached != null) {
      return KegiatanModel.fromJson(cached);
    }

    throw ApiException(message: 'Data kegiatan tidak ditemukan di penyimpanan ponsel.');
  }

  Future<KegiatanModel> createKegiatan(Map<String, dynamic> data) async {
    final response = await apiClient.post(
      ApiEndpoints.kegiatan,
      data: data,
    );

    final resData = response.data;
    if (resData != null && resData['data'] is Map<String, dynamic>) {
      final created = resData['data'] as Map<String, dynamic>;
      await DatabaseHelper.cacheSingleKegiatan(created);
      return KegiatanModel.fromJson(created);
    }

    throw ApiException(message: resData?['message'] ?? 'Gagal membuat sesi kegiatan.');
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await apiClient.put(
        ApiEndpoints.kegiatanStatus(id),
        data: {'status': status},
      );
    } catch (_) {}

    // Always update local status
    await DatabaseHelper.updateKegiatanStatus(id, status);
  }
}
