import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/providers/core_providers.dart';
import 'package:presensi_pmd/core/utils/date_formatter.dart';
import 'package:presensi_pmd/core/widgets/empty_state.dart';
import 'package:presensi_pmd/features/auth/presentation/auth_controller.dart';
import 'package:presensi_pmd/features/kegiatan/domain/kegiatan_model.dart';
import 'package:presensi_pmd/features/kegiatan/presentation/kegiatan_controller.dart';
import 'package:presensi_pmd/features/presensi/presentation/controllers/presensi_controller.dart';
import 'package:presensi_pmd/features/presensi/presentation/widgets/izin_sakit_bottom_sheet.dart';
import 'package:presensi_pmd/features/presensi/presentation/widgets/pemuda_checklist_tile.dart';
import 'package:presensi_pmd/features/presensi/presentation/widgets/summary_bar.dart';
import 'package:presensi_pmd/features/presensi/presentation/screens/rekap_presensi_screen.dart';

class PresensiScreen extends ConsumerStatefulWidget {
  final KegiatanModel kegiatan;

  const PresensiScreen({super.key, required this.kegiatan});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> {
  final _searchController = TextEditingController();
  late KegiatanModel _kegiatan;

  @override
  void initState() {
    super.initState();
    _kegiatan = widget.kegiatan;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider);
      ref.read(presensiControllerProvider.notifier).loadPresensi(
            _kegiatan.id,
            cabangId: auth.user?.cabangId,
            targetPeserta: _kegiatan.targetPeserta,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSync() async {
    final notifier = ref.read(presensiControllerProvider.notifier);
    final count = await notifier.syncAll(_kegiatan.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Berhasil menyinkronkan $count data ke server!'
              : 'Semua data telah sinkron dengan server.'),
          backgroundColor: AppColors.hadir,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openIzinSakitSheet(BuildContext context, pemuda, String defaultStatus) {
    final prefs = ref.read(preferencesHelperProvider);
    final chips = prefs.getQuickChips();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IzinSakitBottomSheet(
        pemuda: pemuda,
        initialStatus: defaultStatus,
        presetChips: chips,
        onSave: (status, keterangan) {
          ref.read(presensiControllerProvider.notifier).setStatus(
                _kegiatan.id,
                pemuda.id,
                status,
                keterangan,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presensiControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final dateObj = DateFormatter.parseTanggal(_kegiatan.tanggal);
    final dateDisplay = dateObj != null
        ? DateFormatter.formatTanggalIndo(dateObj)
        : _kegiatan.tanggal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _kegiatan.namaKegiatan,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$dateDisplay • ${auth.user?.cabang?.namaCabang ?? "Cabang"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        actions: [
          // Sync button
          IconButton(
            icon: state.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sinkronkan Data',
            onPressed: state.isSyncing ? null : _handleSync,
          ),
          // Rekap button
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Rekap Presensi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RekapPresensiScreen(
                    kegiatan: _kegiatan,
                    onStatusChanged: (newStatus) {
                      setState(() {
                        _kegiatan = _kegiatan.copyWith(status: newStatus);
                      });
                      ref
                          .read(kegiatanControllerProvider.notifier)
                          .updateStatus(_kegiatan.id, newStatus);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Realtime Summary Bar
          SummaryBar(
            total: state.total,
            hadir: state.totalHadir,
            izin: state.totalIzin,
            sakit: state.totalSakit,
            alpa: state.totalAlpa,
            unsyncedCount: state.unsyncedCount,
            isSyncing: state.isSyncing,
            onSyncPressed: _handleSync,
          ),

          // Filters & Search Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(presensiControllerProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau NRP pemuda...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(presensiControllerProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Gender Filter Segmented Control & Status Filter
                Row(
                  children: [
                    // Gender Tab Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterTab('Semua', 'semua', state.filterGender),
                          _buildFilterTab('Pemuda (L)', 'L', state.filterGender),
                          _buildFilterTab('Pemudi (P)', 'P', state.filterGender),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Dropdown
                    Expanded(
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: state.filterStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'semua', child: Text('Semua Status')),
                              DropdownMenuItem(value: 'hadir', child: Text('Hadir Saja')),
                              DropdownMenuItem(value: 'izin_sakit', child: Text('Izin / Sakit')),
                              DropdownMenuItem(value: 'alpa', child: Text('Belum Hadir')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(presensiControllerProvider.notifier).setFilterStatus(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Locked Notification Banner if completed
          if (_kegiatan.isSelesai)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sesi presensi ini telah ditutup (selesai). Data terkunci.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // List of Pemuda
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : state.filteredItems.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'Tidak Ada Data Pemuda',
                        message: _searchController.text.isNotEmpty
                            ? 'Tidak ada pemuda yang cocok dengan kata kunci pencarian.'
                            : 'Belum ada data pemuda aktif di cabang ini.',
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          final auth = ref.read(authControllerProvider);
                          await ref.read(presensiControllerProvider.notifier).loadPresensi(
                                _kegiatan.id,
                                cabangId: auth.user?.cabangId,
                                targetPeserta: _kegiatan.targetPeserta,
                              );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: state.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = state.filteredItems[index];
                            return PemudaChecklistTile(
                              item: item,
                              isLocked: _kegiatan.isSelesai,
                              onToggleHadir: () {
                                ref
                                    .read(presensiControllerProvider.notifier)
                                    .toggleHadir(_kegiatan.id, item.pemuda.id);
                              },
                              onSelectIzin: () {
                                _openIzinSakitSheet(context, item.pemuda, 'izin');
                              },
                              onSelectSakit: () {
                                _openIzinSakitSheet(context, item.pemuda, 'sakit');
                              },
                              onResetAlpa: () {
                                ref.read(presensiControllerProvider.notifier).setStatus(
                                      _kegiatan.id,
                                      item.pemuda.id,
                                      'alpa',
                                      null,
                                    );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Floating Bottom Rekap Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RekapPresensiScreen(
                        kegiatan: _kegiatan,
                        onStatusChanged: (newStatus) {
                          setState(() {
                            _kegiatan = _kegiatan.copyWith(status: newStatus);
                          });
                          ref
                              .read(kegiatanControllerProvider.notifier)
                              .updateStatus(_kegiatan.id, newStatus);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Lihat Rekap & Bagikan ke WA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, String currentValue) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () {
        ref.read(presensiControllerProvider.notifier).setFilterGender(value);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
