import 'package:presensi_pmd/core/utils/date_formatter.dart';

class RekapItemEntry {
  final String nama;
  final String? keterangan;

  RekapItemEntry({required this.nama, this.keterangan});

  factory RekapItemEntry.fromJson(Map<String, dynamic> json) {
    return RekapItemEntry(
      nama: (json['name'] ?? json['nama'] ?? json['nama_lengkap'] ?? '-').toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}

class RekapModel {
  final int kegiatanId;
  final String namaKegiatan;
  final String tanggal;
  final String? lokasi;
  final String? namaCabang;
  final String? namaPencatat;
  final int totalPemuda;
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpa;
  final double persentaseHadir;
  final List<RekapItemEntry> daftarIzin;
  final List<RekapItemEntry> daftarSakit;
  final String? serverTeksLaporan;

  RekapModel({
    required this.kegiatanId,
    required this.namaKegiatan,
    required this.tanggal,
    this.lokasi,
    this.namaCabang,
    this.namaPencatat,
    required this.totalPemuda,
    required this.totalHadir,
    required this.totalIzin,
    required this.totalSakit,
    required this.totalAlpa,
    required this.persentaseHadir,
    required this.daftarIzin,
    required this.daftarSakit,
    this.serverTeksLaporan,
  });

  String get teksLaporanWhatsApp {
    if (serverTeksLaporan != null && serverTeksLaporan!.trim().isNotEmpty) {
      return serverTeksLaporan!;
    }

    final dateObj = DateFormatter.parseTanggal(tanggal);
    final tanggalFormatted = dateObj != null
        ? DateFormatter.formatTanggalIndo(dateObj)
        : tanggal;

    final buffer = StringBuffer();
    final cabangTitle = namaCabang != null && namaCabang!.isNotEmpty
        ? namaCabang!.toUpperCase()
        : 'SRAGEN';

    buffer.writeln('*LAPORAN PRESENSI PEMUDA CABANG $cabangTitle*');
    buffer.writeln('Kegiatan: $namaKegiatan');
    buffer.writeln('Hari/Tanggal: $tanggalFormatted');
    if (lokasi != null && lokasi!.isNotEmpty) {
      buffer.writeln('Tempat: $lokasi');
    }
    buffer.writeln('');
    buffer.writeln('*REKAP KEHADIRAN:*');
    buffer.writeln('- Total Pemuda: $totalPemuda orang');
    buffer.writeln('- Hadir: $totalHadir orang (${persentaseHadir.toStringAsFixed(1)}%)');
    buffer.writeln('- Izin: $totalIzin orang');
    buffer.writeln('- Sakit: $totalSakit orang');
    buffer.writeln('- Alpa: $totalAlpa orang');
    buffer.writeln('');

    if (daftarIzin.isNotEmpty) {
      buffer.writeln('*DAFTAR IZIN:*');
      for (var i = 0; i < daftarIzin.length; i++) {
        final item = daftarIzin[i];
        final ket = (item.keterangan != null && item.keterangan!.isNotEmpty)
            ? ' (${item.keterangan})'
            : '';
        buffer.writeln('${i + 1}. ${item.nama}$ket');
      }
      buffer.writeln('');
    }

    if (daftarSakit.isNotEmpty) {
      buffer.writeln('*DAFTAR SAKIT:*');
      for (var i = 0; i < daftarSakit.length; i++) {
        final item = daftarSakit[i];
        final ket = (item.keterangan != null && item.keterangan!.isNotEmpty)
            ? ' (${item.keterangan})'
            : '';
        buffer.writeln('${i + 1}. ${item.nama}$ket');
      }
      buffer.writeln('');
    }

    final pencatat = namaPencatat ?? 'Sekretaris Cabang';
    buffer.writeln('Pencatat: $pencatat');

    return buffer.toString();
  }

  factory RekapModel.fromJson(Map<String, dynamic> json) {
    final kegiatanJson = json['kegiatan'] is Map<String, dynamic>
        ? json['kegiatan'] as Map<String, dynamic>
        : json;

    final stats = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : (json['statistik'] is Map<String, dynamic>
            ? json['statistik'] as Map<String, dynamic>
            : json);

    final izinList = <RekapItemEntry>[];
    final rawIzin = stats['daftar_izin'] ?? json['daftar_izin'];
    if (rawIzin is List) {
      for (final item in rawIzin) {
        if (item is Map<String, dynamic>) {
          izinList.add(RekapItemEntry.fromJson(item));
        } else if (item is String) {
          izinList.add(RekapItemEntry(nama: item));
        }
      }
    }

    final sakitList = <RekapItemEntry>[];
    final rawSakit = stats['daftar_sakit'] ?? json['daftar_sakit'];
    if (rawSakit is List) {
      for (final item in rawSakit) {
        if (item is Map<String, dynamic>) {
          sakitList.add(RekapItemEntry.fromJson(item));
        } else if (item is String) {
          sakitList.add(RekapItemEntry(nama: item));
        }
      }
    }

    final total = stats['total_pemuda'] ?? stats['total'] ?? stats['total_peserta'] ?? 0;
    final hadir = stats['hadir'] ?? stats['total_hadir'] ?? 0;
    final izin = stats['izin'] ?? stats['total_izin'] ?? 0;
    final sakit = stats['sakit'] ?? stats['total_sakit'] ?? 0;
    final alpa = stats['alpa'] ?? stats['total_alpa'] ?? 0;

    double persen = 0.0;
    if (stats['persentase_hadir'] != null) {
      persen = (stats['persentase_hadir'] is num)
          ? (stats['persentase_hadir'] as num).toDouble()
          : double.tryParse(stats['persentase_hadir'].toString()) ?? 0.0;
    } else if (total > 0) {
      persen = (hadir / total) * 100.0;
    }

    final rawKegiatanId = json['kegiatan_id'] ?? kegiatanJson['id'];

    return RekapModel(
      kegiatanId: rawKegiatanId is int
          ? rawKegiatanId
          : int.tryParse(rawKegiatanId?.toString() ?? '') ?? 0,
      namaKegiatan: (kegiatanJson['nama_kegiatan'] ?? kegiatanJson['nama'] ?? 'Kegiatan Presensi').toString(),
      tanggal: (kegiatanJson['tanggal'] ?? '').toString(),
      lokasi: kegiatanJson['lokasi']?.toString(),
      namaCabang: json['nama_cabang']?.toString() ?? kegiatanJson['nama_cabang']?.toString(),
      namaPencatat: json['nama_pencatat']?.toString() ?? json['pencatat']?.toString(),
      totalPemuda: total is int ? total : int.tryParse(total.toString()) ?? 0,
      totalHadir: hadir is int ? hadir : int.tryParse(hadir.toString()) ?? 0,
      totalIzin: izin is int ? izin : int.tryParse(izin.toString()) ?? 0,
      totalSakit: sakit is int ? sakit : int.tryParse(sakit.toString()) ?? 0,
      totalAlpa: alpa is int ? alpa : int.tryParse(alpa.toString()) ?? 0,
      persentaseHadir: persen,
      daftarIzin: izinList,
      daftarSakit: sakitList,
      serverTeksLaporan: (json['whatsapp_text'] ?? json['teks_laporan'])?.toString(),
    );
  }
}
