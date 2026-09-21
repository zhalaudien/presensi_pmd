class ApiEndpoints {
  static const String baseUrl = 'https://pemudamtasragen.my.id/api/v1';

  // Config & Info
  static const String config = '/config';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Cabang Master Data
  static const String cabangPemuda = '/cabang/pemuda';

  // Kegiatan & Presensi
  static const String kegiatan = '/kegiatan';
  static String kegiatanDetail(int id) => '/kegiatan/$id';
  static String kegiatanStatus(int id) => '/kegiatan/$id/status';
  static String presensiSingle(int kegiatanId) => '/kegiatan/$kegiatanId/presensi/single';
  static String presensiBulk(int kegiatanId) => '/kegiatan/$kegiatanId/presensi/bulk';
  static String kegiatanRekap(int kegiatanId) => '/kegiatan/$kegiatanId/rekap';
}
