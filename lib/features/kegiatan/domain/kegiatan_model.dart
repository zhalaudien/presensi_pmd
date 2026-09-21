class KegiatanModel {
  final int id;
  final int cabangId;
  final String namaKegiatan;
  final String tanggal;
  final String? jamMulai;
  final String? jamSelesai;
  final String? lokasi;
  final String? pemateri;
  final String targetPeserta; // 'semua', 'pemuda', 'pemudi'
  final String status; // 'draft', 'berlangsung', 'selesai'
  final String? catatan;
  final int createdBy;

  // Statistics
  final int totalPeserta;
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpa;

  KegiatanModel({
    required this.id,
    required this.cabangId,
    required this.namaKegiatan,
    required this.tanggal,
    this.jamMulai,
    this.jamSelesai,
    this.lokasi,
    this.pemateri,
    this.targetPeserta = 'semua',
    this.status = 'berlangsung',
    this.catatan,
    this.createdBy = 0,
    this.totalPeserta = 0,
    this.totalHadir = 0,
    this.totalIzin = 0,
    this.totalSakit = 0,
    this.totalAlpa = 0,
  });

  bool get isSelesai => status.toLowerCase() == 'selesai';
  bool get isBerlangsung => status.toLowerCase() == 'berlangsung';

  double get persentaseHadir {
    if (totalPeserta <= 0) return 0.0;
    return (totalHadir / totalPeserta) * 100.0;
  }

  factory KegiatanModel.fromJson(Map<String, dynamic> json) {
    int peserta = 0;
    int hadir = 0;
    int izin = 0;
    int sakit = 0;
    int alpa = 0;

    final summaryObj = json['summary'] ?? json['statistik'] ?? json['rekap'];
    if (summaryObj is Map<String, dynamic>) {
      peserta = summaryObj['total_pemuda'] ?? summaryObj['total'] ?? summaryObj['total_peserta'] ?? summaryObj['total_anggota'] ?? 0;
      hadir = summaryObj['hadir'] ?? summaryObj['total_hadir'] ?? 0;
      izin = summaryObj['izin'] ?? summaryObj['total_izin'] ?? 0;
      sakit = summaryObj['sakit'] ?? summaryObj['total_sakit'] ?? 0;
      alpa = summaryObj['alpa'] ?? summaryObj['total_alpa'] ?? 0;
    } else {
      peserta = json['total_peserta'] ?? json['total_anggota'] ?? json['total_pemuda'] ?? 0;
      hadir = json['total_hadir'] ?? json['hadir'] ?? 0;
      izin = json['total_izin'] ?? json['izin'] ?? 0;
      sakit = json['total_sakit'] ?? json['sakit'] ?? 0;
      alpa = json['total_alpa'] ?? json['alpa'] ?? 0;
    }

    return KegiatanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      cabangId: json['cabang_id'] is int
          ? json['cabang_id']
          : int.tryParse(json['cabang_id']?.toString() ?? '') ?? 0,
      namaKegiatan: (json['nama_kegiatan'] ?? json['nama'] ?? 'Kegiatan Cabang').toString(),
      tanggal: (json['tanggal'] ?? '').toString(),
      jamMulai: json['jam_mulai']?.toString(),
      jamSelesai: json['jam_selesai']?.toString(),
      lokasi: json['lokasi']?.toString(),
      pemateri: json['pemateri']?.toString(),
      targetPeserta: (json['target_peserta'] ?? 'semua').toString(),
      status: (json['status'] ?? 'berlangsung').toString(),
      catatan: json['catatan']?.toString(),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : (json['creator'] is Map ? json['creator']['id'] ?? 0 : int.tryParse(json['created_by']?.toString() ?? '') ?? 0),
      totalPeserta: peserta,
      totalHadir: hadir,
      totalIzin: izin,
      totalSakit: sakit,
      totalAlpa: alpa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cabang_id': cabangId,
      'nama_kegiatan': namaKegiatan,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'lokasi': lokasi,
      'pemateri': pemateri,
      'target_peserta': targetPeserta,
      'status': status,
      'catatan': catatan,
      'created_by': createdBy,
      'total_peserta': totalPeserta,
      'total_hadir': totalHadir,
      'total_izin': totalIzin,
      'total_sakit': totalSakit,
      'total_alpa': totalAlpa,
    };
  }

  KegiatanModel copyWith({
    int? id,
    int? cabangId,
    String? namaKegiatan,
    String? tanggal,
    String? jamMulai,
    String? jamSelesai,
    String? lokasi,
    String? pemateri,
    String? targetPeserta,
    String? status,
    String? catatan,
    int? createdBy,
    int? totalPeserta,
    int? totalHadir,
    int? totalIzin,
    int? totalSakit,
    int? totalAlpa,
  }) {
    return KegiatanModel(
      id: id ?? this.id,
      cabangId: cabangId ?? this.cabangId,
      namaKegiatan: namaKegiatan ?? this.namaKegiatan,
      tanggal: tanggal ?? this.tanggal,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      lokasi: lokasi ?? this.lokasi,
      pemateri: pemateri ?? this.pemateri,
      targetPeserta: targetPeserta ?? this.targetPeserta,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      createdBy: createdBy ?? this.createdBy,
      totalPeserta: totalPeserta ?? this.totalPeserta,
      totalHadir: totalHadir ?? this.totalHadir,
      totalIzin: totalIzin ?? this.totalIzin,
      totalSakit: totalSakit ?? this.totalSakit,
      totalAlpa: totalAlpa ?? this.totalAlpa,
    );
  }
}
