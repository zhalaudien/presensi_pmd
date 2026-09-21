import 'package:intl/intl.dart';

class DateFormatter {
  static final List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Ahad',
  ];

  static final List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatTanggalIndo(DateTime date) {
    final hari = _namaHari[date.weekday - 1];
    final bulan = _namaBulan[date.month - 1];
    return '$hari, ${date.day} $bulan ${date.year}';
  }

  static String formatTanggalSingkat(DateTime date) {
    final bulan = _namaBulan[date.month - 1];
    return '${date.day} $bulan ${date.year}';
  }

  static String formatTanggalDb(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatWaktuDb(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static String formatJam(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    // If format is HH:mm:ss, take HH:mm
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  static DateTime? parseTanggal(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }
}
