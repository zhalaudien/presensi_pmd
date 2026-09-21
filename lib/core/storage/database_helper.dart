import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'presensi_pmd.db';
  static const int _dbVersion = 1;

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Table Pemuda Cache
        await db.execute('''
          CREATE TABLE pemuda_cache (
            id INTEGER PRIMARY KEY,
            cabang_id INTEGER,
            nama TEXT,
            nrp TEXT,
            jenis_kelamin TEXT,
            alamat TEXT,
            no_hp TEXT,
            foto_url TEXT,
            raw_json TEXT
          )
        ''');

        // Table Kegiatan Cache
        await db.execute('''
          CREATE TABLE kegiatan_cache (
            id INTEGER PRIMARY KEY,
            cabang_id INTEGER,
            nama_kegiatan TEXT,
            tanggal TEXT,
            jam_mulai TEXT,
            jam_selesai TEXT,
            lokasi TEXT,
            pemateri TEXT,
            target_peserta TEXT,
            status TEXT,
            catatan TEXT,
            created_by INTEGER,
            total_peserta INTEGER DEFAULT 0,
            total_hadir INTEGER DEFAULT 0,
            total_izin INTEGER DEFAULT 0,
            total_sakit INTEGER DEFAULT 0,
            total_alpa INTEGER DEFAULT 0,
            raw_json TEXT,
            is_local_created INTEGER DEFAULT 0
          )
        ''');

        // Table Presensi Offline Queue
        await db.execute('''
          CREATE TABLE presensi_offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kegiatan_presensi_id INTEGER NOT NULL,
            pemuda_id INTEGER NOT NULL,
            status_kehadiran TEXT NOT NULL,
            keterangan TEXT,
            waktu_presensi TEXT,
            device_info TEXT,
            is_synced INTEGER DEFAULT 0,
            updated_at TEXT,
            UNIQUE(kegiatan_presensi_id, pemuda_id) ON CONFLICT REPLACE
          )
        ''');

        // Indexes for performance
        await db.execute('CREATE INDEX idx_pemuda_cabang ON pemuda_cache (cabang_id);');
        await db.execute('CREATE INDEX idx_kegiatan_cabang ON kegiatan_cache (cabang_id);');
        await db.execute('CREATE INDEX idx_queue_kegiatan ON presensi_offline_queue (kegiatan_presensi_id);');
        await db.execute('CREATE INDEX idx_queue_synced ON presensi_offline_queue (is_synced);');
      },
    );
  }

  // ================= PEMUDA OPERATIONS =================
  static Future<void> cachePemudaList(List<Map<String, dynamic>> pemudaList) async {
    final db = await database;
    final batch = db.batch();
    for (final item in pemudaList) {
      final id = item['id'] as int;
      final cabangId = item['cabang_id'] as int?;
      final nama = (item['nama'] ?? item['nama_lengkap'] ?? '').toString();
      final nrp = (item['nrp'] ?? item['nomor_anggota'] ?? '').toString();
      final jk = (item['jenis_kelamin'] ?? item['jk'] ?? 'L').toString().toUpperCase();
      final alamat = (item['alamat'] ?? '').toString();
      final noHp = (item['no_hp'] ?? item['telepon'] ?? '').toString();
      final fotoUrl = (item['foto_url'] ?? item['foto'] ?? '').toString();

      batch.insert(
        'pemuda_cache',
        {
          'id': id,
          'cabang_id': cabangId,
          'nama': nama,
          'nrp': nrp,
          'jenis_kelamin': jk.startsWith('P') ? 'P' : 'L',
          'alamat': alamat,
          'no_hp': noHp,
          'foto_url': fotoUrl,
          'raw_json': jsonEncode(item),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedPemudaList({
    int? cabangId,
    String? query,
    String? jenisKelamin,
  }) async {
    final db = await database;
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (cabangId != null) {
      whereClause += 'cabang_id = ?';
      whereArgs.add(cabangId);
    }

    if (jenisKelamin != null && jenisKelamin != 'semua' && jenisKelamin.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'jenis_kelamin = ?';
      whereArgs.add(jenisKelamin.toUpperCase());
    }

    if (query != null && query.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(nama LIKE ? OR nrp LIKE ?)';
      whereArgs.add('%${query.trim()}%');
      whereArgs.add('%${query.trim()}%');
    }

    return await db.query(
      'pemuda_cache',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'nama ASC',
    );
  }

  // ================= KEGIATAN OPERATIONS =================
  static Future<void> cacheKegiatanList(List<Map<String, dynamic>> list) async {
    final db = await database;
    final batch = db.batch();
    for (final item in list) {
      final id = item['id'] as int;
      batch.insert(
        'kegiatan_cache',
        {
          'id': id,
          'cabang_id': item['cabang_id'] as int?,
          'nama_kegiatan': (item['nama_kegiatan'] ?? '').toString(),
          'tanggal': (item['tanggal'] ?? '').toString(),
          'jam_mulai': (item['jam_mulai'] ?? '').toString(),
          'jam_selesai': (item['jam_selesai'] ?? '').toString(),
          'lokasi': (item['lokasi'] ?? '').toString(),
          'pemateri': (item['pemateri'] ?? '').toString(),
          'target_peserta': (item['target_peserta'] ?? 'semua').toString(),
          'status': (item['status'] ?? 'berlangsung').toString(),
          'catatan': (item['catatan'] ?? '').toString(),
          'created_by': item['created_by'] as int? ?? 0,
          'total_peserta': item['total_peserta'] as int? ?? item['total_anggota'] as int? ?? 0,
          'total_hadir': item['total_hadir'] as int? ?? 0,
          'total_izin': item['total_izin'] as int? ?? 0,
          'total_sakit': item['total_sakit'] as int? ?? 0,
          'total_alpa': item['total_alpa'] as int? ?? 0,
          'raw_json': jsonEncode(item),
          'is_local_created': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> cacheSingleKegiatan(Map<String, dynamic> item) async {
    final db = await database;
    final id = item['id'] as int;
    await db.insert(
      'kegiatan_cache',
      {
        'id': id,
        'cabang_id': item['cabang_id'] as int?,
        'nama_kegiatan': (item['nama_kegiatan'] ?? '').toString(),
        'tanggal': (item['tanggal'] ?? '').toString(),
        'jam_mulai': (item['jam_mulai'] ?? '').toString(),
        'jam_selesai': (item['jam_selesai'] ?? '').toString(),
        'lokasi': (item['lokasi'] ?? '').toString(),
        'pemateri': (item['pemateri'] ?? '').toString(),
        'target_peserta': (item['target_peserta'] ?? 'semua').toString(),
        'status': (item['status'] ?? 'berlangsung').toString(),
        'catatan': (item['catatan'] ?? '').toString(),
        'created_by': item['created_by'] as int? ?? 0,
        'total_peserta': item['total_peserta'] as int? ?? item['total_anggota'] as int? ?? 0,
        'total_hadir': item['total_hadir'] as int? ?? 0,
        'total_izin': item['total_izin'] as int? ?? 0,
        'total_sakit': item['total_sakit'] as int? ?? 0,
        'total_alpa': item['total_alpa'] as int? ?? 0,
        'raw_json': jsonEncode(item),
        'is_local_created': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedKegiatanList({int? cabangId}) async {
    final db = await database;
    return await db.query(
      'kegiatan_cache',
      where: cabangId != null ? 'cabang_id = ?' : null,
      whereArgs: cabangId != null ? [cabangId] : null,
      orderBy: 'tanggal DESC, id DESC',
    );
  }

  static Future<Map<String, dynamic>?> getCachedKegiatanById(int id) async {
    final db = await database;
    final results = await db.query(
      'kegiatan_cache',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<void> updateKegiatanStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'kegiatan_cache',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= PRESENSI QUEUE OPERATIONS =================
  static Future<void> savePresensiLocal({
    required int kegiatanId,
    required int pemudaId,
    required String status,
    String? keterangan,
    String? waktu,
    String? deviceInfo,
    bool isSynced = false,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'presensi_offline_queue',
      {
        'kegiatan_presensi_id': kegiatanId,
        'pemuda_id': pemudaId,
        'status_kehadiran': status.toLowerCase(),
        'keterangan': keterangan,
        'waktu_presensi': waktu ?? now,
        'device_info': deviceInfo,
        'is_synced': isSynced ? 1 : 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPresensiForKegiatan(int kegiatanId) async {
    final db = await database;
    return await db.query(
      'presensi_offline_queue',
      where: 'kegiatan_presensi_id = ?',
      whereArgs: [kegiatanId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPresensiQueueUnsynced(int kegiatanId) async {
    final db = await database;
    return await db.query(
      'presensi_offline_queue',
      where: 'kegiatan_presensi_id = ? AND is_synced = 0',
      whereArgs: [kegiatanId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllPresensiQueueUnsynced() async {
    final db = await database;
    return await db.query(
      'presensi_offline_queue',
      where: 'is_synced = 0',
    );
  }

  static Future<void> markPresensiSynced({
    required int kegiatanId,
    required List<int> pemudaIds,
  }) async {
    if (pemudaIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(pemudaIds.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE presensi_offline_queue SET is_synced = 1 WHERE kegiatan_presensi_id = ? AND pemuda_id IN ($placeholders)',
      [kegiatanId, ...pemudaIds],
    );
  }

  static Future<int> getUnsyncedCount(int kegiatanId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM presensi_offline_queue WHERE kegiatan_presensi_id = ? AND is_synced = 0',
      [kegiatanId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM presensi_offline_queue WHERE is_synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('pemuda_cache');
    await db.delete('kegiatan_cache');
    await db.delete('presensi_offline_queue');
  }
}
