import 'package:flutter/material.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/widgets/app_badge.dart';
import 'package:presensi_pmd/features/presensi/domain/presensi_item_model.dart';

class PemudaChecklistTile extends StatelessWidget {
  final PresensiItemModel item;
  final bool isLocked;
  final VoidCallback onToggleHadir;
  final VoidCallback onSelectIzin;
  final VoidCallback onSelectSakit;
  final VoidCallback onResetAlpa;

  const PemudaChecklistTile({
    super.key,
    required this.item,
    this.isLocked = false,
    required this.onToggleHadir,
    required this.onSelectIzin,
    required this.onSelectSakit,
    required this.onResetAlpa,
  });

  @override
  Widget build(BuildContext context) {
    final pemuda = item.pemuda;
    final isHadir = item.isHadir;
    final isIzin = item.isIzin;
    final isSakit = item.isSakit;

    Color tileBorderColor = AppColors.border;
    Color tileBgColor = AppColors.surface;

    if (isHadir) {
      tileBorderColor = AppColors.hadir.withOpacity(0.35);
      tileBgColor = AppColors.hadirBg.withOpacity(0.18);
    } else if (isIzin) {
      tileBorderColor = AppColors.izin.withOpacity(0.35);
      tileBgColor = AppColors.izinBg.withOpacity(0.18);
    } else if (isSakit) {
      tileBorderColor = AppColors.sakit.withOpacity(0.35);
      tileBgColor = AppColors.sakitBg.withOpacity(0.18);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tileBorderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLocked ? null : onToggleHadir,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Instant Checkbox Button
                InkWell(
                  onTap: isLocked ? null : onToggleHadir,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isHadir ? AppColors.hadir : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHadir ? AppColors.hadir : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isHadir
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Avatar / Inisial
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: pemuda.isLakiLaki
                          ? AppColors.primary.withOpacity(0.1)
                          : const Color(0xFFFCE7F3),
                      child: Text(
                        pemuda.initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: pemuda.isLakiLaki
                              ? AppColors.primary
                              : const Color(0xFFDB2777),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: pemuda.isLakiLaki
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFEC4899),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          pemuda.jenisKelamin,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Nama & NRP & Keterangan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              pemuda.nama,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isHadir
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary.withOpacity(0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isSynced) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Tersimpan lokal (belum sinkron)',
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 14,
                                color: AppColors.sakit,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (pemuda.nrp != null && pemuda.nrp!.isNotEmpty) ...[
                            Text(
                              'NRP: ${pemuda.nrp}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          AppBadge(status: item.status),
                        ],
                      ),
                      if ((isIzin || isSakit) &&
                          item.keterangan != null &&
                          item.keterangan!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Ket: ${item.keterangan}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isIzin ? AppColors.izin : AppColors.sakit,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // More Actions Menu
                if (!isLocked)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'hadir':
                          onToggleHadir();
                          break;
                        case 'izin':
                          onSelectIzin();
                          break;
                        case 'sakit':
                          onSelectSakit();
                          break;
                        case 'alpa':
                          onResetAlpa();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'hadir',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: AppColors.hadir, size: 18),
                            SizedBox(width: 10),
                            Text('Tandai Hadir',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'izin',
                        child: Row(
                          children: [
                            Icon(Icons.assignment_late_outlined,
                                color: AppColors.izin, size: 18),
                            SizedBox(width: 10),
                            Text('Tandai Izin...',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sakit',
                        child: Row(
                          children: [
                            Icon(Icons.healing_outlined,
                                color: AppColors.sakit, size: 18),
                            SizedBox(width: 10),
                            Text('Tandai Sakit...',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'alpa',
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: AppColors.alpa, size: 18),
                            SizedBox(width: 10),
                            Text('Reset / Belum Hadir',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
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
}
