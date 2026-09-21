import 'package:flutter/material.dart';
import 'package:presensi_pmd/core/constants/app_colors.dart';
import 'package:presensi_pmd/core/utils/date_formatter.dart';
import 'package:presensi_pmd/core/widgets/custom_button.dart';
import 'package:presensi_pmd/core/widgets/custom_text_field.dart';

class BuatKegiatanDialog extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic> data) onSubmit;

  const BuatKegiatanDialog({super.key, required this.onSubmit});

  @override
  State<BuatKegiatanDialog> createState() => _BuatKegiatanDialogState();
}

class _BuatKegiatanDialogState extends State<BuatKegiatanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _pemateriController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _jamMulai = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 22, minute: 0);
  String _targetPeserta = 'semua';
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    _pemateriController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'nama_kegiatan': _namaController.text.trim(),
      'tanggal': DateFormatter.formatTanggalDb(_selectedDate),
      'jam_mulai': _formatTimeOfDay(_jamMulai),
      'jam_selesai': _formatTimeOfDay(_jamSelesai),
      'lokasi': _lokasiController.text.trim().isEmpty ? null : _lokasiController.text.trim(),
      'pemateri': _pemateriController.text.trim().isEmpty ? null : _pemateriController.text.trim(),
      'target_peserta': _targetPeserta,
      'status': 'berlangsung',
      'catatan': _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
    };

    final success = await widget.onSubmit(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buka Sesi Presensi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Buat agenda kegiatan presensi baru',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nama Kegiatan
                CustomTextField(
                  controller: _namaController,
                  label: 'Nama Kegiatan / Pengajian *',
                  hintText: 'Misal: Kajian Rutin Malam Ahad',
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama kegiatan wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Tanggal Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Kegiatan *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatter.formatTanggalIndo(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Jam Mulai & Jam Selesai
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Mulai',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _jamMulai,
                              );
                              if (picked != null) {
                                setState(() => _jamMulai = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _jamMulai.format(context),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jam Selesai',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _jamSelesai,
                              );
                              if (picked != null) {
                                setState(() => _jamSelesai = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _jamSelesai.format(context),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lokasi
                CustomTextField(
                  controller: _lokasiController,
                  label: 'Tempat / Lokasi',
                  hintText: 'Contoh: Gedung Dakwah Cabang / Masjid Al-Huda',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      size: 20, color: AppColors.textSecondary),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Pemateri
                CustomTextField(
                  controller: _pemateriController,
                  label: 'Pemateri / Pembicara',
                  hintText: 'Nama Ustadz / Pembicara',
                  prefixIcon: const Icon(Icons.person_pin_outlined,
                      size: 20, color: AppColors.textSecondary),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Target Peserta
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Peserta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Semua')),
                            selected: _targetPeserta == 'semua',
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _targetPeserta == 'semua'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _targetPeserta = 'semua');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemuda (L)')),
                            selected: _targetPeserta == 'pemuda',
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _targetPeserta == 'pemuda'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _targetPeserta = 'pemuda');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemudi (P)')),
                            selected: _targetPeserta == 'pemudi',
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _targetPeserta == 'pemudi'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _targetPeserta = 'pemudi');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Catatan
                CustomTextField(
                  controller: _catatanController,
                  label: 'Catatan Tambahan',
                  hintText: 'Keterangan opsional...',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Batal',
                        isOutlined: true,
                        backgroundColor: AppColors.textSecondary,
                        textColor: AppColors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: 'Buka Sesi',
                        isLoading: _isLoading,
                        icon: Icons.check_circle_outline,
                        onPressed: _handleSubmit,
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
