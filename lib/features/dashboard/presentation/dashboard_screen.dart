import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/providers/core_providers.dart';
import 'package:presensi_pmd/core/utils/date_formatter.dart';
import 'package:presensi_pmd/core/widgets/app_badge.dart';
import 'package:presensi_pmd/core/widgets/empty_state.dart';
import 'package:presensi_pmd/features/auth/presentation/auth_controller.dart';
import 'package:presensi_pmd/features/auth/presentation/login_screen.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';
import 'package:presensi_pmd/features/kegiatan/presentation/kegiatan_controller.dart';
import 'package:presensi_pmd/features/kegiatan/presentation/widgets/buat_kegiatan_dialog.dart';
import 'package:presensi_pmd/features/presensi/presentation/screens/presensi_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _filterTab = 'semua'; // 'semua', 'berlangsung', 'selesai'
  bool _isPreCaching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(kegiatanControllerProvider.notifier).loadKegiatanList(forceRefresh: true);
  }

  void _handlePreCachePemuda() async {
    setState(() => _isPreCaching = true);
    final presensiRepo = ref.read(presensiRepositoryProvider);
    final auth = ref.read(authControllerProvider);
    try {
      final list = await presensiRepo.getPemudaCabang(
        cabangId: auth.user?.cabangId,
        forceRefresh: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil memperbarui cache ${list.length} data pemuda cabang!'),
            backgroundColor: AppColors.hadir,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data pemuda: ${e.toString()}'),
            backgroundColor: AppColors.alpa,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPreCaching = false);
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Pastikan seluruh data presensi telah disinkronkan ke server sebelum Anda keluar.',
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
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _openBuatKegiatanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => BuatKegiatanDialog(
        onSubmit: (data) async {
          final success = await ref
              .read(kegiatanControllerProvider.notifier)
              .createKegiatan(data);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sesi kegiatan presensi berhasil dibuka!'),
                backgroundColor: AppColors.hadir,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final kegiatanState = ref.watch(kegiatanControllerProvider);
    final user = authState.user;
    final cabang = user?.cabang;

    var filteredKegiatan = kegiatanState.kegiatanList;
    if (_filterTab == 'berlangsung') {
      filteredKegiatan = filteredKegiatan.where((k) => k.isBerlangsung).toList();
    } else if (_filterTab == 'selesai') {
      filteredKegiatan = filteredKegiatan.where((k) => k.isSelesai).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_turned_in, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Presensi PMD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  cabang?.namaCabang ?? 'Cabang Sragen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isPreCaching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Cache Data Pemuda Cabang',
            onPressed: _isPreCaching ? null : _handlePreCachePemuda,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar Akun',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref
              .read(kegiatanControllerProvider.notifier)
              .loadKegiatanList(forceRefresh: true);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // Welcome Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assalamu\'alaikum,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? 'Sekretaris Cabang',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cabang?.namaCabang ?? 'Cabang',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.offline_pin_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Mendukung Offline-First. Presensi dapat dicatat tanpa sinyal internet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sesi Kegiatan Title & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Sesi Presensi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Filter Chips
                  Row(
                    children: [
                      _buildChip('Semua', 'semua'),
                      const SizedBox(width: 6),
                      _buildChip('Aktif', 'berlangsung'),
                      const SizedBox(width: 6),
                      _buildChip('Selesai', 'selesai'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Kegiatan Cards
            if (kegiatanState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filteredKegiatan.isEmpty)
              EmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Belum Ada Sesi Kegiatan',
                message: _filterTab == 'berlangsung'
                    ? 'Tidak ada kegiatan yang sedang aktif saat ini.'
                    : 'Tekan tombol "Buka Sesi Baru" untuk memulai presensi kegiatan cabang.',
                actionText: 'Buka Sesi Baru',
                onAction: _openBuatKegiatanDialog,
              )
            else
              ...filteredKegiatan.map((kegiatan) {
                return _buildKegiatanCard(context, kegiatan);
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buka Sesi Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _openBuatKegiatanDialog,
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filterTab == value;
    return InkWell(
      onTap: () => setState(() => _filterTab = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildKegiatanCard(BuildContext context, KegiatanModel kegiatan) {
    final dateObj = DateFormatter.parseTanggal(kegiatan.tanggal);
    final dateDisplay = dateObj != null
        ? DateFormatter.formatTanggalIndo(dateObj)
        : kegiatan.tanggal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PresensiScreen(kegiatan: kegiatan),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Target & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kegiatan.targetPeserta == 'pemuda'
                            ? 'Khusus Pemuda (L)'
                            : kegiatan.targetPeserta == 'pemudi'
                                ? 'Khusus Pemudi (P)'
                                : 'Semua Peserta',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    AppBadge(status: kegiatan.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Nama Kegiatan
                Text(
                  kegiatan.namaKegiatan,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Tanggal & Jam
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      dateDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (kegiatan.jamMulai != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatJam(kegiatan.jamMulai),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),

                // Lokasi
                if (kegiatan.lokasi != null && kegiatan.lokasi!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          kegiatan.lokasi!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),

                // Bottom Stats & Action Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildMiniStat('Hadir', kegiatan.totalHadir, AppColors.hadir),
                        const SizedBox(width: 12),
                        _buildMiniStat('Izin', kegiatan.totalIzin, AppColors.izin),
                        const SizedBox(width: 12),
                        _buildMiniStat('Sakit', kegiatan.totalSakit, AppColors.sakit),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'Buka Presensi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int val, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $val',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
