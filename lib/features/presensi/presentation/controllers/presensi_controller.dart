import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presensi_pmd/core/providers/core_providers.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';
import 'package:presensi_pmd/features/presensi/data/presensi_repository.dart';
import 'package:presensi_pmd/features/presensi/domain/presensi_item_model.dart';
import 'package:presensi_pmd/features/presensi/domain/rekap_model.dart';

class PresensiState {
  final bool isLoading;
  final bool isSyncing;
  final List<PresensiItemModel> items;
  final String filterGender; // 'semua', 'L', 'P'
  final String filterStatus; // 'semua', 'hadir', 'izin_sakit', 'alpa'
  final String searchQuery;
  final int unsyncedCount;
  final String? errorMessage;

  PresensiState({
    this.isLoading = false,
    this.isSyncing = false,
    this.items = const [],
    this.filterGender = 'semua',
    this.filterStatus = 'semua',
    this.searchQuery = '',
    this.unsyncedCount = 0,
    this.errorMessage,
  });

  int get total => items.length;
  int get totalHadir => items.where((e) => e.isHadir).length;
  int get totalIzin => items.where((e) => e.isIzin).length;
  int get totalSakit => items.where((e) => e.isSakit).length;
  int get totalAlpa => items.where((e) => e.isAlpa).length;

  List<PresensiItemModel> get filteredItems {
    return items.where((item) {
      // 1. Gender Filter
      if (filterGender == 'L' && !item.pemuda.isLakiLaki) return false;
      if (filterGender == 'P' && !item.pemuda.isPerempuan) return false;

      // 2. Status Filter
      if (filterStatus == 'hadir' && !item.isHadir) return false;
      if (filterStatus == 'izin_sakit' && !item.isIzin && !item.isSakit) return false;
      if (filterStatus == 'alpa' && !item.isAlpa) return false;

      // 3. Search Query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final nameMatch = item.pemuda.nama.toLowerCase().contains(query);
        final nrpMatch = item.pemuda.nrp?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !nrpMatch) return false;
      }

      return true;
    }).toList();
  }

  PresensiState copyWith({
    bool? isLoading,
    bool? isSyncing,
    List<PresensiItemModel>? items,
    String? filterGender,
    String? filterStatus,
    String? searchQuery,
    int? unsyncedCount,
    String? errorMessage,
  }) {
    return PresensiState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      items: items ?? this.items,
      filterGender: filterGender ?? this.filterGender,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      errorMessage: errorMessage,
    );
  }
}

class PresensiController extends StateNotifier<PresensiState> {
  final PresensiRepository _repo;

  PresensiController(this._repo) : super(PresensiState());

  Future<void> loadPresensi(
    int kegiatanId, {
    int? cabangId,
    String? targetPeserta,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repo.getPresensiItemsForKegiatan(
        kegiatanId: kegiatanId,
        cabangId: cabangId,
        targetPeserta: targetPeserta,
      );
      final unsynced = await _repo.getUnsyncedCount(kegiatanId);

      state = state.copyWith(
        isLoading: false,
        items: items,
        unsyncedCount: unsynced,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleHadir(int kegiatanId, int pemudaId) async {
    final currentIndex = state.items.indexWhere((e) => e.pemuda.id == pemudaId);
    if (currentIndex == -1) return;

    final current = state.items[currentIndex];
    // Toggle: if already hadir, switch to alpa; if not hadir, switch to hadir
    final newStatus = current.isHadir ? 'alpa' : 'hadir';

    // Optimistic UI Update
    final updatedList = List<PresensiItemModel>.from(state.items);
    updatedList[currentIndex] = current.copyWith(
      status: newStatus,
      keterangan: null,
      waktuPresensi: DateTime.now().toIso8601String(),
      isSynced: false,
    );

    state = state.copyWith(
      items: updatedList,
      unsyncedCount: state.unsyncedCount + 1,
    );

    // Save locally and trigger API in background
    final synced = await _repo.recordPresensi(
      kegiatanId: kegiatanId,
      pemudaId: pemudaId,
      status: newStatus,
      keterangan: null,
    );

    if (synced) {
      final postIndex = state.items.indexWhere((e) => e.pemuda.id == pemudaId);
      if (postIndex != -1) {
        final syncedList = List<PresensiItemModel>.from(state.items);
        syncedList[postIndex] = syncedList[postIndex].copyWith(isSynced: true);
        final unsyncedCount = await _repo.getUnsyncedCount(kegiatanId);
        state = state.copyWith(items: syncedList, unsyncedCount: unsyncedCount);
      }
    }
  }

  Future<void> setStatus(
    int kegiatanId,
    int pemudaId,
    String status,
    String? keterangan,
  ) async {
    final currentIndex = state.items.indexWhere((e) => e.pemuda.id == pemudaId);
    if (currentIndex == -1) return;

    final current = state.items[currentIndex];

    // Optimistic UI Update
    final updatedList = List<PresensiItemModel>.from(state.items);
    updatedList[currentIndex] = current.copyWith(
      status: status.toLowerCase(),
      keterangan: keterangan,
      waktuPresensi: DateTime.now().toIso8601String(),
      isSynced: false,
    );

    state = state.copyWith(
      items: updatedList,
      unsyncedCount: state.unsyncedCount + 1,
    );

    final synced = await _repo.recordPresensi(
      kegiatanId: kegiatanId,
      pemudaId: pemudaId,
      status: status,
      keterangan: keterangan,
    );

    if (synced) {
      final postIndex = state.items.indexWhere((e) => e.pemuda.id == pemudaId);
      if (postIndex != -1) {
        final syncedList = List<PresensiItemModel>.from(state.items);
        syncedList[postIndex] = syncedList[postIndex].copyWith(isSynced: true);
        final unsyncedCount = await _repo.getUnsyncedCount(kegiatanId);
        state = state.copyWith(items: syncedList, unsyncedCount: unsyncedCount);
      }
    }
  }

  Future<int> syncAll(int kegiatanId) async {
    state = state.copyWith(isSyncing: true);
    try {
      final count = await _repo.syncOfflineQueue(kegiatanId);

      // Reload presensi items to reflect fully synced state
      final items = await _repo.getPresensiItemsForKegiatan(kegiatanId: kegiatanId);
      final unsynced = await _repo.getUnsyncedCount(kegiatanId);

      state = state.copyWith(
        isSyncing: false,
        items: items,
        unsyncedCount: unsynced,
      );
      return count;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Gagal sinkronisasi: ${e.toString()}',
      );
      return 0;
    }
  }

  void setFilterGender(String gender) {
    state = state.copyWith(filterGender: gender);
  }

  void setFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<RekapModel> getRekap(
    KegiatanModel kegiatan,
    String? namaCabang,
    String? namaPencatat,
  ) async {
    return await _repo.getRekap(
      kegiatanId: kegiatan.id,
      kegiatan: kegiatan,
      items: state.items,
      namaCabang: namaCabang,
      namaPencatat: namaPencatat,
    );
  }
}

final presensiControllerProvider =
    StateNotifierProvider<PresensiController, PresensiState>((ref) {
  final repo = ref.watch(presensiRepositoryProvider);
  return PresensiController(repo);
});
