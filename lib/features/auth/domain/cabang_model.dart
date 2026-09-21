class CabangModel {
  final int id;
  final String namaCabang;
  final String? kodeCabang;
  final String? alamat;
  final int? totalPemuda;

  CabangModel({
    required this.id,
    required this.namaCabang,
    this.kodeCabang,
    this.alamat,
    this.totalPemuda,
  });

  factory CabangModel.fromJson(Map<String, dynamic> json) {
    return CabangModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      namaCabang: (json['nama_cabang'] ?? json['nama'] ?? 'Cabang').toString(),
      kodeCabang: json['kode_cabang']?.toString(),
      alamat: json['alamat']?.toString(),
      totalPemuda: json['total_pemuda'] is int
          ? json['total_pemuda']
          : int.tryParse(json['total_pemuda']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_cabang': namaCabang,
      'kode_cabang': kodeCabang,
      'alamat': alamat,
      'total_pemuda': totalPemuda,
    };
  }
}
