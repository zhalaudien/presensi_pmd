class PemudaModel {
  final int id;
  final int? cabangId;
  final String nama;
  final String? nrp;
  final String jenisKelamin; // 'L' or 'P'
  final String? alamat;
  final String? noHp;
  final String? fotoUrl;
  final bool isAktif;

  PemudaModel({
    required this.id,
    this.cabangId,
    required this.nama,
    this.nrp,
    this.jenisKelamin = 'L',
    this.alamat,
    this.noHp,
    this.fotoUrl,
    this.isAktif = true,
  });

  bool get isLakiLaki => jenisKelamin.toUpperCase() == 'L';
  bool get isPerempuan => jenisKelamin.toUpperCase() == 'P';

  String get initials {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory PemudaModel.fromJson(Map<String, dynamic> json) {
    final jk = (json['gender'] ?? json['jenis_kelamin'] ?? json['jk'] ?? 'L')
        .toString()
        .toUpperCase();

    final rawId = json['pemuda_id'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final nama = (json['name'] ?? json['nama'] ?? json['nama_lengkap'] ?? 'Pemuda').toString();
    final nrp = (json['registration_number'] ?? json['nrp'] ?? json['nomor_anggota'] ?? json['kode_anggota'])?.toString();
    final noHp = (json['phone'] ?? json['no_hp'] ?? json['telepon'] ?? json['no_telp'])?.toString();

    return PemudaModel(
      id: id,
      cabangId: json['cabang_id'] is int
          ? json['cabang_id']
          : int.tryParse(json['cabang_id']?.toString() ?? ''),
      nama: nama,
      nrp: nrp,
      jenisKelamin: jk.startsWith('P') ? 'P' : 'L',
      alamat: json['alamat']?.toString(),
      noHp: noHp,
      fotoUrl: (json['foto_url'] ?? json['foto'])?.toString(),
      isAktif: json['status_keaktifan'] == null
          ? true
          : (json['status_keaktifan'] == 'aktif' ||
              json['status_keaktifan'] == 1 ||
              json['status_keaktifan'] == true ||
              json['status_verifikasi'] == 'verified'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cabang_id': cabangId,
      'nama': nama,
      'nrp': nrp,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'no_hp': noHp,
      'foto_url': fotoUrl,
      'is_aktif': isAktif,
    };
  }
}
