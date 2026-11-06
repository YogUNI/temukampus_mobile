import 'package:flutter/material.dart';

/// Palet warna resmi TemuKampus Mobile (100% konsisten dengan Web Design System).
/// Aturan Aksesibilitas: DILARANG meletakkan teks putih di atas warna [signal].
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color cobalt = Color(0xFF2447F5);       // Aksi utama, link, SKP, fokus
  static const Color cobaltDark = Color(0xFF1B38C9);   // Hover / Pressed state
  static const Color cobaltLight = Color(0xFFE9EDFE);  // Soft cobalt background
  static const Color ink = Color(0xFF12162B);          // Teks utama, border tegas, hard-shadow
  static const Color paper = Color(0xFFF4F6FB);        // Latar aplikasi (putih kebiruan dingin)
  static const Color surface = Color(0xFFFFFFFF);      // Kartu, bottom sheet, formulir
  static const Color signal = Color(0xFFFF7A2F);       // Titik "temu", badge sisa kuota, aksen oranye
  static const Color signalLight = Color(0xFFFFEFE6);  // Soft signal background

  // Semantic Colors & Ticket Statuses
  static const Color mint = Color(0xFF14A37F);         // Sukses, Tiket Terkonfirmasi
  static const Color mintLight = Color(0xFFD8F5EC);    // Latar status Terkonfirmasi
  static const Color mintText = Color(0xFF0B6B54);

  static const Color amber = Color(0xFF8A5A00);        // Status Menunggu Verifikasi
  static const Color amberLight = Color(0xFFFFF1CC);
  static const Color warning = amber;
  static const Color warningLight = amberLight;
  static const Color warningText = amber;

  static const Color danger = Color(0xFFD93C3C);       // Galat, Ditolak, Kuota Habis
  static const Color dangerLight = Color(0xFFFDE3E3);
  static const Color dangerText = Color(0xFFC62F2F);

  // Neutral Scales
  static const Color ink100 = Color(0xFFEBEFF8);       // Garis batas / divider halus
  static const Color ink200 = Color(0xFFD4DCED);       // Border kartu normal
  static const Color ink300 = Color(0xFFB0BBD8);
  static const Color ink400 = Color(0xFF8F99B7);       // Placeholder & icon sekunder
  static const Color ink500 = Color(0xFF5C6482);       // Teks sekunder (jam, lokasi, meta)
  static const Color ink700 = Color(0xFF2E385D);
  static const Color ink800 = Color(0xFF1C2242);       // Dark mode card surface
  static const Color ink900 = Color(0xFF12162B);       // Dark mode background

  // Hard Shadow khas stiker TemuKampus
  static const BoxShadow stickerShadow = BoxShadow(
    color: ink,
    offset: Offset(3, 3),
    blurRadius: 0,
    spreadRadius: 0,
  );

  static const BoxShadow stickerShadowSmall = BoxShadow(
    color: ink,
    offset: Offset(2, 2),
    blurRadius: 0,
    spreadRadius: 0,
  );

  static const BoxShadow stickerShadowLarge = BoxShadow(
    color: ink,
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
  );
}

