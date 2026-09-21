import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_pmd/features/presensi/domain/pemuda_model.dart';
import 'package:presensi_pmd/features/presensi/domain/presensi_item_model.dart';
import 'package:presensi_pmd/features/presensi/domain/rekap_model.dart';

void main() {
  group('Presensi PMD Unit Tests', () {
    test('PemudaModel parsing and initials', () {
      final json = {
        'id': 142,
        'nama': 'Ahmad Fauzi',
        'nrp': 'PMD-0142',
        'jenis_kelamin': 'L',
      };
      final pemuda = PemudaModel.fromJson(json);

      expect(pemuda.id, 142);
      expect(pemuda.nama, 'Ahmad Fauzi');
      expect(pemuda.initials, 'AF');
      expect(pemuda.isLakiLaki, true);
      expect(pemuda.isPerempuan, false);
    });

    test('PresensiItemModel status toggle and copyWith', () {
      final pemuda = PemudaModel(id: 1, nama: 'Budi Santoso');
      final item = PresensiItemModel(pemuda: pemuda, status: 'alpa');

      expect(item.isHadir, false);
      expect(item.isAlpa, true);

      final hadirItem = item.copyWith(status: 'hadir');
      expect(hadirItem.isHadir, true);
    });

    test('RekapModel WhatsApp text generation', () {
      final rekap = RekapModel(
        kegiatanId: 1,
        namaKegiatan: 'Pengajian Rutin Pemuda',
        tanggal: '2026-09-20',
        lokasi: 'Gedung Dakwah Cabang',
        namaCabang: 'Sragen Kota',
        namaPencatat: 'Sekretaris Cabang',
        totalPemuda: 50,
        totalHadir: 40,
        totalIzin: 5,
        totalSakit: 2,
        totalAlpa: 3,
        persentaseHadir: 80.0,
        daftarIzin: [
          RekapItemEntry(nama: 'Fulan', keterangan: 'Lembur'),
        ],
        daftarSakit: [
          RekapItemEntry(nama: 'Alan', keterangan: 'Demam'),
        ],
      );

      final waText = rekap.teksLaporanWhatsApp;
      expect(waText.contains('*LAPORAN PRESENSI PEMUDA CABANG SRAGEN KOTA*'), true);
      expect(waText.contains('Hadir: 40 orang (80.0%)'), true);
      expect(waText.contains('1. Fulan (Lembur)'), true);
      expect(waText.contains('1. Alan (Demam)'), true);
    });
  });
}
