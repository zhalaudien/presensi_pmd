import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const AppBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'hadir':
        bg = AppColors.hadirBg;
        fg = AppColors.hadir;
        label = 'HADIR';
        break;
      case 'izin':
        bg = AppColors.izinBg;
        fg = AppColors.izin;
        label = 'IZIN';
        break;
      case 'sakit':
        bg = AppColors.sakitBg;
        fg = AppColors.sakit;
        label = 'SAKIT';
        break;
      case 'alpa':
        bg = AppColors.alpaBg;
        fg = AppColors.alpa;
        label = 'ALPA';
        break;
      case 'berlangsung':
        bg = AppColors.hadirBg;
        fg = AppColors.hadir;
        label = 'BERLANGSUNG';
        break;
      case 'selesai':
        bg = AppColors.pendingBg;
        fg = AppColors.textSecondary;
        label = 'SELESAI';
        break;
      case 'draft':
        bg = AppColors.sakitBg;
        fg = AppColors.sakit;
        label = 'DRAFT';
        break;
      default:
        bg = AppColors.pendingBg;
        fg = AppColors.textSecondary;
        label = status.toUpperCase();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
