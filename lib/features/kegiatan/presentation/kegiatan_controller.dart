import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presensi_pmd/core/providers/core_providers.dart';
import 'package:presensi_pmd/features/kegiatan/data/kegiatan_repository.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';

class KegiatanState {
  final bool isLoading;
  final List<KegiatanModel> kegiatanList;
  final String? errorMessage;

  KegiatanState({
    this.isLoading = false,
    this.kegiatanList = const [],
    this.errorMessage,
  });

  KegiatanState copyWith({
    bool? isLoading,
    List<KegiatanModel>? kegiatanList,
    String? errorMessage,
  }) {
    return KegiatanState(
      isLoading: isLoading ?? this.isLoading,
      kegiatanList: kegiatanList ?? this.kegiatanList,
      errorMessage: errorMessage,
    );
  }
}

class KegiatanController extends StateNotifier<KegiatanState> {
  final KegiatanRepository _kegiatanRepo;

  KegiatanController(this._kegiatanRepo) : super(KegiatanState()) {
    loadKegiatanList();
  }

  Future<void> loadKegiatanList({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _kegiatanRepo.getKegiatanList(forceRefresh: forceRefresh);
      state = state.copyWith(isLoading: false, kegiatanList: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createKegiatan(Map<String, dynamic> data) async {
    try {
      final created = await _kegiatanRepo.createKegiatan(data);
      state = state.copyWith(
        kegiatanList: [created, ...state.kegiatanList],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await _kegiatanRepo.updateStatus(id, status);
      state = state.copyWith(
        kegiatanList: state.kegiatanList.map((k) {
          if (k.id == id) {
            return k.copyWith(status: status);
          }
          return k;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final kegiatanControllerProvider =
    StateNotifierProvider<KegiatanController, KegiatanState>((ref) {
  final repo = ref.watch(kegiatanRepositoryProvider);
  return KegiatanController(repo);
});
