import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistem tipografi resmi TemuKampus Mobile:
/// - [Bricolage Grotesque] untuk Display, Heading, Angka, dan Stempel Status.
/// - [Plus Jakarta Sans] untuk Body, UI, Form Input, dan Keterangan Meta.
class AppTypography {
  AppTypography._();

  // === Display & Headings (Bricolage Grotesque) ===

  /// Hero title di beranda atau landing (28pt, w800)
  static TextStyle hero = GoogleFonts.bricolageGrotesque(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Judul halaman / Header besar (22pt, w700)
  static TextStyle titleLarge = GoogleFonts.bricolageGrotesque(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Judul kartu acara / Section header (18pt, w700)
  static TextStyle titleMedium = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );

  /// Sub-heading kartu / label stempel (15pt, w600)
  static TextStyle titleSmall = GoogleFonts.bricolageGrotesque(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// Teks stempel tiket fisik miring (-3°)
  static TextStyle ticketStamp = GoogleFonts.bricolageGrotesque(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  // === Body & Form Text (Plus Jakarta Sans) ===

  /// Teks paragraf utama (16pt, w500)
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.5,
  );

  /// Teks deskripsi / penjelasan sekunder (14pt, w400)
  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink500,
    height: 1.45,
  );

  /// Teks bantuan kecil / disclaimer (12pt, w400)
  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.ink500,
    height: 1.4,
  );

  /// Label form / button text (14pt, w600)
  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// Label kecil / input label (12pt, w600)
  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// Pill badge / chip text (11pt, w700)
  static TextStyle badge = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  /// Kode unik pendaftaran / Angka transfer (18pt, monospace/grotesque w800)
  static TextStyle numericCode = GoogleFonts.bricolageGrotesque(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: AppColors.ink,
  );
}

