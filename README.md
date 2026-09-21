# Presensi PMD (Aplikasi Mobile Android Flutter)
**Sistem Terintegrasi Pendataan & Presensi Pemuda MTA Perwakilan Sragen**

- **Package ID:** `id.or.mta.presensipmd`
- **Target Platform:** Android (minSdk: 21, targetSdk: 34)
- **Framework:** Flutter 3.47.2 / Dart 3.13.2+
- **File APK Release:** [`presensi-pmd-v1.0.0.apk`](./presensi-pmd-v1.0.0.apk) (53 MB)
- **Target REST API:** `https://pemudamtasragen.my.id/api/v1`

---

## 📖 Dokumentasi Lengkap
- Dokumen Cetak Biru (Blueprint): [AGENTS.md](./AGENTS.md)
- Dokumen Teknis & Laporan Pengembangan: [DOKUMENTASI.md](./DOKUMENTASI.md)

---

## 🚀 Fitur Utama
1. **Offline-First:** Catat presensi tetap berjalan di masjid/gedung cabang walau tanpa internet, otomatis tersimpan di SQLite lokal ponsel dan disinkronkan saat ada sinyal.
2. **Pencarian Kilat & Filter (60 FPS):** Cari nama anggota atau nomor registrasi pemuda (NRP) secara instan tanpa jeda.
3. **Centang Cepat (Fast Checklist):** Cukup satu sentuhan untuk menandai status Hadir.
4. **Modal Izin & Sakit Responsif:** Dilengkapi tombol preset alasan cepat (*quick chips*) dan isian catatan bebas.
5. **Header Statistik Realtime (Pinned Top):** Pantau persentase dan jumlah Hadir, Izin, Sakit, Alpa, serta status antrean sinkronisasi offline.
6. **Ekspor & Berbagi WhatsApp Instan:** Satu sentuhan untuk membagikan rekapitulasi kehadiran rapi ke grup WhatsApp pengurus cabang.
7. **Kunci Sesi Kegiatan:** Fitur finalisasi kegiatan presensi agar data tidak berubah setelah selesai.

---

## 🔑 Akun Uji Coba Lapangan
- **Username:** `jenar`
- **Password:** `234234`
- **Peran:** Sekretaris Cabang Jenar

---

## 🛠️ Perintah Pengembangan

```bash
# Menjalankan pengujian unit
flutter test

# Memeriksa analisis kode
flutter analyze

# Membangun APK Release baru
flutter build apk --release
```
