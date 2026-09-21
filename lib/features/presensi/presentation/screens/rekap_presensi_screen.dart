import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/widgets/custom_button.dart';
import 'package:presensi_pmd/features/auth/presentation/auth_controller.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';
import 'package:presensi_pmd/features/presensi/presentation/controllers/presensi_controller.dart';
import 'package:presensi_pmd/features/presensi/domain/rekap_model.dart';

class RekapPresensiScreen extends ConsumerStatefulWidget {
  final KegiatanModel kegiatan;
  final Function(String newStatus)? onStatusChanged;

  const RekapPresensiScreen({
    super.key,
    required this.kegiatan,
    this.onStatusChanged,
  });

  @override
  ConsumerState<RekapPresensiScreen> createState() => _RekapPresensiScreenState();
}

class _RekapPresensiScreenState extends ConsumerState<RekapPresensiScreen> {
  RekapModel? _rekap;
  bool _isLoading = true;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    _loadRekap();
  }

  void _loadRekap() async {
    final auth = ref.read(authControllerProvider);
    final notifier = ref.read(presensiControllerProvider.notifier);
    final rekap = await notifier.getRekap(
      widget.kegiatan,
      auth.user?.cabang?.namaCabang,
      auth.user?.name,
    );

    if (mounted) {
      setState(() {
        _rekap = rekap;
        _isLoading = false;
      });
    }
  }

  void _shareToWhatsApp() {
    if (_rekap == null) return;
    // ignore: deprecated_member_use
    Share.share(
      _rekap!.teksLaporanWhatsApp,
      subject: 'Rekap Presensi Pemuda Cabang - ${_rekap!.namaKegiatan}',
    );
  }

  void _copyToClipboard() {
    if (_rekap == null) return;
    Clipboard.setData(ClipboardData(text: _rekap!.teksLaporanWhatsApp));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks laporan berhasil disalin ke clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLockKegiatan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kunci & Selesaikan Presensi?'),
        content: const Text(
          'Setelah sesi presensi diselesaikan, data kehadiran akan dikunci dan rekapitulasi dianggap final.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alpa,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLocking = true);
              final presensiNotifier = ref.read(presensiControllerProvider.notifier);
              // Sync before locking
              await presensiNotifier.syncAll(widget.kegiatan.id);
              widget.onStatusChanged?.call('selesai');
              if (mounted) {
                setState(() => _isLocking = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesi presensi berhasil dikunci & diselesaikan.'),
                    backgroundColor: AppColors.hadir,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Ya, Kunci Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Rekapitulasi Presensi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Salin Teks',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan ke WA',
            onPressed: _shareToWhatsApp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _rekap == null
              ? const Center(child: Text('Gagal memuat rekap presensi.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _rekap!.namaKegiatan,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _rekap!.namaCabang != null
                                  ? 'Cabang ${_rekap!.namaCabang}'
                                  : 'Cabang Sragen',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Percentage Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.hadirBg,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '${_rekap!.persentaseHadir.toStringAsFixed(1)}% Kehadiran',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.hadir,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Grid of 4 counters
                            Row(
                              children: [
                                _buildCounterCard('Total Pemuda', '${_rekap!.totalPemuda}',
                                    AppColors.textPrimary, AppColors.surfaceVariant),
                                const SizedBox(width: 8),
                                _buildCounterCard('Hadir', '${_rekap!.totalHadir}',
                                    AppColors.hadir, AppColors.hadirBg),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildCounterCard('Izin', '${_rekap!.totalIzin}',
                                    AppColors.izin, AppColors.izinBg),
                                const SizedBox(width: 8),
                                _buildCounterCard('Sakit', '${_rekap!.totalSakit}',
                                    AppColors.sakit, AppColors.sakitBg),
                                const SizedBox(width: 8),
                                _buildCounterCard('Alpa', '${_rekap!.totalAlpa}',
                                    AppColors.alpa, AppColors.alpaBg),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daftar Izin Card
                      if (_rekap!.daftarIzin.isNotEmpty) ...[
                        _buildDetailCard(
                          title: 'Daftar Pemuda Izin (${_rekap!.daftarIzin.length})',
                          icon: Icons.assignment_late_outlined,
                          color: AppColors.izin,
                          bgColor: AppColors.izinBg,
                          entries: _rekap!.daftarIzin,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Daftar Sakit Card
                      if (_rekap!.daftarSakit.isNotEmpty) ...[
                        _buildDetailCard(
                          title: 'Daftar Pemuda Sakit (${_rekap!.daftarSakit.length})',
                          icon: Icons.healing_outlined,
                          color: AppColors.sakit,
                          bgColor: AppColors.sakitBg,
                          entries: _rekap!.daftarSakit,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // WhatsApp Formatted Text Preview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        size: 18, color: AppColors.hadir),
                                    SizedBox(width: 8),
                                    Text(
                                      'Format Laporan WhatsApp',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.hadir,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      size: 18, color: AppColors.hadir),
                                  tooltip: 'Salin Teks',
                                  onPressed: _copyToClipboard,
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFBBF7D0)),
                            const SizedBox(height: 4),
                            SelectableText(
                              _rekap!.teksLaporanWhatsApp,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      CustomButton(
                        text: 'Bagikan Laporan ke WhatsApp',
                        icon: Icons.share_rounded,
                        backgroundColor: const Color(0xFF25D366),
                        onPressed: _shareToWhatsApp,
                      ),
                      const SizedBox(height: 10),

                      if (!widget.kegiatan.isSelesai)
                        CustomButton(
                          text: 'Kunci & Selesaikan Kegiatan',
                          icon: Icons.lock_outline_rounded,
                          isLoading: _isLocking,
                          isOutlined: true,
                          backgroundColor: AppColors.alpa,
                          textColor: AppColors.alpa,
                          onPressed: _confirmLockKegiatan,
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCounterCard(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<RekapItemEntry> entries,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        children: [
                          TextSpan(
                            text: item.nama,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item.keterangan != null && item.keterangan!.isNotEmpty)
                            TextSpan(
                              text: ' — ${item.keterangan}',
                              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
