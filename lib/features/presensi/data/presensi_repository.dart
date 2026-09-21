import 'dart:async';
import 'package:dio/dio.dart';
import 'package:presensi_pmd/core/constants/api_endpoints.dart';
import 'package:presensi_pmd/core/network/api_client.dart';
import 'package:presensi_pmd/core/network/connectivity_service.dart';
import 'package:presensi_pmd/core/storage/database_helper.dart';
import 'package:presensi_pmd/core/utils/date_formatter.dart';
import 'package:presensi_pmd/core/utils/device_util.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';
import 'package:presensi_pmd/features/presensi/domain/pemuda_model.dart';
import 'package:presensi_pmd/features/presensi/domain/presensi_item_model.dart';
import 'package:presensi_pmd/features/presensi/domain/rekap_model.dart';

class PresensiRepository {
  final ApiClient apiClient;
  final ConnectivityService connectivityService;

  PresensiRepository({
    required this.apiClient,
    required this.connectivityService,
  });

  Future<List<PemudaModel>> getPemudaCabang({int? cabangId, bool forceRefresh = false}) async {
    final isOnline = await connectivityService.checkOnline();

    if (isOnline && forceRefresh) {
      try {
        // Use a short 8-second timeout so the UI never freezes if endpoint is slow
        final response = await apiClient.get(
          ApiEndpoints.cabangPemuda,
          options: Options(
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        final resData = response.data;
        if (resData != null && resData['data'] is List) {
          final listRaw = (resData['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();

          await DatabaseHelper.cachePemudaList(listRaw);
          return listRaw.map((e) => PemudaModel.fromJson(e)).toList();
        }
      } catch (_) {
        // Fallback to SQLite cache on timeout or error
      }
    }

    final cached = await DatabaseHelper.getCachedPemudaList(cabangId: cabangId);
    return cached.map((e) => PemudaModel.fromJson(e)).toList();
  }

  Future<List<PresensiItemModel>> getPresensiItemsForKegiatan({
    required int kegiatanId,
    int? cabangId,
    String? targetPeserta,
  }) async {
    final isOnline = await connectivityService.checkOnline();
    List<PresensiItemModel>? onlineItems;

    // 1. If online, fetch kegiatan detail directly (returns checklist in 2s)
    if (isOnline) {
      try {
        final response = await apiClient.get(ApiEndpoints.kegiatanDetail(kegiatanId));
        final resData = response.data;
        if (resData != null && resData['data'] is Map<String, dynamic>) {
          final data = resData['data'] as Map<String, dynamic>;
          final checklist = data['checklist'] ?? data['presensi'] ?? data['presensi_detail'];

          if (checklist is List && checklist.isNotEmpty) {
            final List<Map<String, dynamic>> pemudaToCache = [];
            final List<PresensiItemModel> items = [];

            for (final item in checklist) {
              if (item is Map<String, dynamic>) {
                final pemuda = PemudaModel.fromJson(item);
                pemudaToCache.add({
                  'id': pemuda.id,
                  'cabang_id': cabangId,
                  'nama': pemuda.nama,
                  'nrp': pemuda.nrp,
                  'jenis_kelamin': pemuda.jenisKelamin,
                  'alamat': pemuda.alamat,
                  'no_hp': pemuda.noHp,
                  'foto_url': pemuda.fotoUrl,
                });

                final status = (item['status_kehadiran'] ?? 'alpa').toString().toLowerCase();
                final ket = item['keterangan']?.toString();
                final waktu = item['waktu_presensi']?.toString();

                items.add(PresensiItemModel(
                  pemuda: pemuda,
                  status: status,
                  keterangan: ket,
                  waktuPresensi: waktu,
                  isSynced: true,
                ));
              }
            }

            // Cache pemuda data into local SQLite
            DatabaseHelper.cachePemudaList(pemudaToCache).ignore();
            onlineItems = items;
          }
        }
      } catch (_) {
        // Fallback to local cache if network call fails
      }
    }

    // 2. Fetch local offline queue records
    final localQueue = await DatabaseHelper.getPresensiForKegiatan(kegiatanId);
    final Map<int, Map<String, dynamic>> localPresensiMap = {};
    for (final row in localQueue) {
      final pemudaId = row['pemuda_id'] as int;
      localPresensiMap[pemudaId] = row;
    }

    List<PresensiItemModel> result = [];

    if (onlineItems != null && onlineItems.isNotEmpty) {
      // Merge online items with local unsynced edits
      for (final item in onlineItems) {
        if (localPresensiMap.containsKey(item.pemuda.id)) {
          final local = localPresensiMap[item.pemuda.id]!;
          final isSynced = (local['is_synced'] as int? ?? 0) == 1;
          result.add(item.copyWith(
            status: (local['status_kehadiran'] ?? 'alpa').toString(),
            keterangan: local['keterangan']?.toString(),
            waktuPresensi: local['waktu_presensi']?.toString(),
            isSynced: isSynced,
          ));
        } else {
          result.add(item);
        }
      }
    } else {
      // Load offline from SQLite cache
      final cachedPemuda = await DatabaseHelper.getCachedPemudaList(cabangId: cabangId);
      final pemudaList = cachedPemuda.map((e) => PemudaModel.fromJson(e)).toList();

      for (final pemuda in pemudaList) {
        if (localPresensiMap.containsKey(pemuda.id)) {
          final local = localPresensiMap[pemuda.id]!;
          final status = (local['status_kehadiran'] ?? 'alpa').toString();
          final ket = local['keterangan']?.toString();
          final waktu = local['waktu_presensi']?.toString();
          final isSynced = (local['is_synced'] as int? ?? 0) == 1;

          result.add(PresensiItemModel(
            pemuda: pemuda,
            status: status,
            keterangan: ket,
            waktuPresensi: waktu,
            isSynced: isSynced,
          ));
        } else {
          result.add(PresensiItemModel(
            pemuda: pemuda,
            status: 'alpa',
            isSynced: true,
          ));
        }
      }
    }

    // 3. Filter by target peserta (pemuda / pemudi / semua)
    if (targetPeserta != null && targetPeserta != 'semua') {
      if (targetPeserta == 'pemuda') {
        result = result.where((p) => p.pemuda.isLakiLaki).toList();
      } else if (targetPeserta == 'pemudi') {
        result = result.where((p) => p.pemuda.isPerempuan).toList();
      }
    }

    return result;
  }

  Future<bool> recordPresensi({
    required int kegiatanId,
    required int pemudaId,
    required String status,
    String? keterangan,
  }) async {
    final now = DateFormatter.formatWaktuDb(DateTime.now());
    final deviceInfo = await DeviceUtil.getDeviceInfo();
    final isOnline = await connectivityService.checkOnline();

    // 1. Always save locally first (Offline-First Auto-Save)
    await DatabaseHelper.savePresensiLocal(
      kegiatanId: kegiatanId,
      pemudaId: pemudaId,
      status: status,
      keterangan: keterangan,
      waktu: now,
      deviceInfo: deviceInfo,
      isSynced: false,
    );

    // 2. If online, attempt realtime single save
    if (isOnline) {
      try {
        final res = await apiClient.post(
          ApiEndpoints.presensiSingle(kegiatanId),
          data: {
            'pemuda_id': pemudaId,
            'status_kehadiran': status.toLowerCase(),
            'keterangan': keterangan,
            'waktu_presensi': now,
            'device_info': deviceInfo,
          },
        );

        if (res.data != null && res.data['success'] == true) {
          await DatabaseHelper.markPresensiSynced(
            kegiatanId: kegiatanId,
            pemudaIds: [pemudaId],
          );
          return true;
        }
      } catch (_) {
        // Stays in offline queue
      }
    }

    return false; // Saved offline, pending sync
  }

  Future<int> syncOfflineQueue(int kegiatanId) async {
    final unsynced = await DatabaseHelper.getPresensiQueueUnsynced(kegiatanId);
    if (unsynced.isEmpty) return 0;

    final deviceInfo = await DeviceUtil.getDeviceInfo();
    final presensiList = unsynced.map((row) {
      return {
        'pemuda_id': row['pemuda_id'],
        'status_kehadiran': row['status_kehadiran'],
        'keterangan': row['keterangan'],
        'waktu_presensi': row['waktu_presensi'],
      };
    }).toList();

    try {
      final response = await apiClient.post(
        ApiEndpoints.presensiBulk(kegiatanId),
        data: {
          'device_info': deviceInfo,
          'presensi_list': presensiList,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final syncedIds = unsynced.map((e) => e['pemuda_id'] as int).toList();
        await DatabaseHelper.markPresensiSynced(
          kegiatanId: kegiatanId,
          pemudaIds: syncedIds,
        );
        return syncedIds.length;
      }
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }

    return 0;
  }

  Future<int> getUnsyncedCount(int kegiatanId) async {
    return await DatabaseHelper.getUnsyncedCount(kegiatanId);
  }

  Future<RekapModel> getRekap({
    required int kegiatanId,
    required KegiatanModel kegiatan,
    required List<PresensiItemModel> items,
    String? namaCabang,
    String? namaPencatat,
  }) async {
    final isOnline = await connectivityService.checkOnline();

    if (isOnline) {
      try {
        final response = await apiClient.get(ApiEndpoints.kegiatanRekap(kegiatanId));
        final resData = response.data;
        if (resData != null && resData['data'] is Map<String, dynamic>) {
          return RekapModel.fromJson(resData['data'] as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    // Fallback offline computation from current items
    final total = items.length;
    final hadir = items.where((e) => e.isHadir).length;
    final izin = items.where((e) => e.isIzin).length;
    final sakit = items.where((e) => e.isSakit).length;
    final alpa = items.where((e) => e.isAlpa).length;

    final daftarIzin = items
        .where((e) => e.isIzin)
        .map((e) => RekapItemEntry(nama: e.pemuda.nama, keterangan: e.keterangan))
        .toList();

    final daftarSakit = items
        .where((e) => e.isSakit)
        .map((e) => RekapItemEntry(nama: e.pemuda.nama, keterangan: e.keterangan))
        .toList();

    final persen = total > 0 ? (hadir / total) * 100.0 : 0.0;

    return RekapModel(
      kegiatanId: kegiatanId,
      namaKegiatan: kegiatan.namaKegiatan,
      tanggal: kegiatan.tanggal,
      lokasi: kegiatan.lokasi,
      namaCabang: namaCabang,
      namaPencatat: namaPencatat,
      totalPemuda: total,
      totalHadir: hadir,
      totalIzin: izin,
      totalSakit: sakit,
      totalAlpa: alpa,
      persentaseHadir: persen,
      daftarIzin: daftarIzin,
      daftarSakit: daftarSakit,
    );
  }
}
