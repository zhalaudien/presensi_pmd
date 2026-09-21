import 'pemuda_model.dart';

class PresensiItemModel {
  final PemudaModel pemuda;
  final String status; // 'hadir', 'izin', 'sakit', 'alpa'
  final String? keterangan;
  final String? waktuPresensi;
  final bool isSynced;

  PresensiItemModel({
    required this.pemuda,
    this.status = 'alpa',
    this.keterangan,
    this.waktuPresensi,
    this.isSynced = true,
  });

  bool get isHadir => status.toLowerCase() == 'hadir';
  bool get isIzin => status.toLowerCase() == 'izin';
  bool get isSakit => status.toLowerCase() == 'sakit';
  bool get isAlpa => status.toLowerCase() == 'alpa';

  PresensiItemModel copyWith({
    PemudaModel? pemuda,
    String? status,
    String? keterangan,
    String? waktuPresensi,
    bool? isSynced,
  }) {
    return PresensiItemModel(
      pemuda: pemuda ?? this.pemuda,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      waktuPresensi: waktuPresensi ?? this.waktuPresensi,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory PresensiItemModel.fromDetailJson(Map<String, dynamic> json, PemudaModel pemuda) {
    return PresensiItemModel(
      pemuda: pemuda,
      status: (json['status_kehadiran'] ?? 'alpa').toString().toLowerCase(),
      keterangan: json['keterangan']?.toString(),
      waktuPresensi: json['waktu_presensi']?.toString(),
      isSynced: true,
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'pemuda_id': pemuda.id,
      'status_kehadiran': status.toLowerCase(),
      'keterangan': keterangan,
      'waktu_presensi': waktuPresensi,
    };
  }
}
