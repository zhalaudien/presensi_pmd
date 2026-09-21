import 'package:flutter/material.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/widgets/custom_button.dart';
import 'package:presensi_pmd/core/widgets/custom_text_field.dart';
import 'package:presensi_pmd/features/presensi/domain/pemuda_model.dart';

class IzinSakitBottomSheet extends StatefulWidget {
  final PemudaModel pemuda;
  final String initialStatus; // 'izin' or 'sakit'
  final String? initialKeterangan;
  final List<String> presetChips;
  final Function(String status, String? keterangan) onSave;

  const IzinSakitBottomSheet({
    super.key,
    required this.pemuda,
    required this.initialStatus,
    this.initialKeterangan,
    this.presetChips = const [],
    required this.onSave,
  });

  @override
  State<IzinSakitBottomSheet> createState() => _IzinSakitBottomSheetState();
}

class _IzinSakitBottomSheetState extends State<IzinSakitBottomSheet> {
  late String _status;
  late final TextEditingController _keteranganController;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _keteranganController = TextEditingController(text: widget.initialKeterangan);
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.presetChips.isNotEmpty
        ? widget.presetChips
        : [
            'Lembur / Shift Kerja',
            'Tugas Belajar / Kuliah',
            'Sedang di Luar Kota',
            'Acara Keluarga',
            'Kondisi Kurang Sehat / Sakit',
            'Urusan Mendesak',
          ];

    final isIzin = _status.toLowerCase() == 'izin';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.pemuda.isLakiLaki
                      ? AppColors.izinBg
                      : const Color(0xFFFCE7F3),
                  radius: 20,
                  child: Text(
                    widget.pemuda.initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.pemuda.isLakiLaki
                          ? AppColors.izin
                          : const Color(0xFFDB2777),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pemuda.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'NRP: ${widget.pemuda.nrp ?? "-"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Toggle Izin or Sakit
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _status = 'izin'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isIzin ? AppColors.izinBg : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isIzin ? AppColors.izin : AppColors.border,
                          width: isIzin ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 18,
                            color: isIzin ? AppColors.izin : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'IZIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isIzin ? AppColors.izin : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _status = 'sakit'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isIzin ? AppColors.sakitBg : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isIzin ? AppColors.sakit : AppColors.border,
                          width: !isIzin ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.healing_outlined,
                            size: 18,
                            color: !isIzin ? AppColors.sakit : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SAKIT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !isIzin ? AppColors.sakit : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Preset Quick Chips
            const Text(
              'Pilihan Alasan Cepat:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) {
                final isSelected = _keteranganController.text == chip;
                return ActionChip(
                  label: Text(chip),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: isSelected
                      ? (isIzin ? AppColors.izin : AppColors.sakit)
                      : AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? (isIzin ? AppColors.izin : AppColors.sakit)
                          : AppColors.border,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _keteranganController.text = chip;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Text input for detail
            CustomTextField(
              controller: _keteranganController,
              label: 'Keterangan Tambahan / Alasan',
              hintText: 'Tuliskan alasan lengkap...',
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Batal',
                    isOutlined: true,
                    backgroundColor: AppColors.textSecondary,
                    textColor: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Simpan Status',
                    backgroundColor: isIzin ? AppColors.izin : AppColors.sakit,
                    onPressed: () {
                      final ket = _keteranganController.text.trim();
                      widget.onSave(_status, ket.isEmpty ? null : ket);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
