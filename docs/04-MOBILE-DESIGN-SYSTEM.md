# TemuKampus Mobile — Design System & Flutter UI Tokens

Spesifikasi desain antarmuka Flutter untuk memastikan identitas visual **TemuKampus Mobile** identik 100% dengan versi web (`docs/04-DESIGN.md`).

---

## 1. Filosofi & Motif Utama: TIKET FISIK

Ciri khas TemuKampus yang membedakannya dari aplikasi kampus lain adalah **Motif Tiket**:
1. **Notch & Tear Line:** Kartu tiket memiliki lekukan setengah lingkaran di sisi samping kiri dan kanan dengan garis sobekan putus-putus (`DottedLine`).
2. **Offset Hard Shadow ("Sticker Style"):** Elemen tombol utama dan kartu unggulan memiliki bayangan keras offset tanpa blur (`BoxShadow(offset: Offset(3, 3), blurRadius: 0)`), terinspirasi dari stiker kampus.
3. **Stempel Miring (Stamp):** Status pendaftaran ditampilkan seperti cap stempel resmi dengan rotasi halus (-3° hingga -5°).

---

## 2. Palet Warna (`AppColors`)

```dart
// lib/app/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Warna Inti Brand
  static const Color cobalt = Color(0xFF2447F5);       // Aksi utama, link, SKP, fokus
  static const Color cobaltDark = Color(0xFF1B38C9);   // Hover / Pressed state
  static const Color ink = Color(0xFF12162B);          // Teks utama, border hitam, hard-shadow
  static const Color paper = Color(0xFFF4F6FB);        // Latar belakang aplikasi (putih kebiruan dingin)
  static const Color surface = Color(0xFFFFFFFF);      // Kartu, bottom sheet, formulir
  static const Color signal = Color(0xFFFF7A2F);       // Titik "temu", badge sisa kuota, aksen oranye

  // Warna Semantik & Status Tiket
  static const Color mint = Color(0xFF14A37F);         // Sukses, Tiket Terkonfirmasi
  static const Color mintLight = Color(0xFFD8F5EC);    // Latar status Terkonfirmasi
  static const Color mintText = Color(0xFF0B6B54);

  static const Color amber = Color(0xFF8A5A00);        // Status Menunggu Verifikasi
  static const Color amberLight = Color(0xFFFFF1CC);

  static const Color danger = Color(0xFFD93C3C);       // Galat, Ditolak, Kuota Habis
  static const Color dangerLight = Color(0xFFFDE3E3);
  static const Color dangerText = Color(0xFFC62F2F);

  // Skala Netral Ink
  static const Color ink100 = Color(0xFFEBEFF8);       // Garis batas / divider halus
  static const Color ink200 = Color(0xFFD4DCED);       // Border kartu normal
  static const Color ink400 = Color(0xFF8F99B7);       // Placeholder & icon sekunder
  static const Color ink500 = Color(0xFF5C6482);       // Teks sekunder (keterangan jam/lokasi)
  static const Color ink800 = Color(0xFF1C2242);       // Dark mode card surface
  static const Color ink900 = Color(0xFF12162B);       // Dark mode background
}
```

> **Aturan Aksesibilitas (Kontras):**
> - Jangan pernah meletakkan teks putih di atas warna `signal` oranye (kontras rendah 2.6:1). Teks di atas `signal` **wajib memakai warna `ink`**.
> - Teks sekunder minimal menggunakan `ink500` (kontras 5.8:1 di atas latar putih).

---

## 3. Tipografi (`AppTypography`)

Menggunakan package `google_fonts`:
- **Display / Judul / Stempel:** **Bricolage Grotesque** (berkarakter, tegas, ramah).
- **Body / Form / Meta:** **Plus Jakarta Sans** (sangat mudah dibaca di layar HP kecil).

```dart
// lib/app/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Display Font (Bricolage Grotesque)
  static TextStyle hero = GoogleFonts.bricolageGrotesque(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static TextStyle titleLarge = GoogleFonts.bricolageGrotesque(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static TextStyle titleMedium = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Body Font (Plus Jakarta Sans)
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink500,
    height: 1.4,
  );

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle badge = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
```

---

## 4. Komponen Kustom: Tiket dengan Notch Cutout (`TicketCard`)

Widget kartu tiket dengan takik setengah lingkaran di kiri dan kanan menggunakan `CustomClipper`:

```dart
// lib/app/theme/components/ticket_clipper.dart
import 'package:flutter/material.dart';

class TicketClipper extends CustomClipper<Path> {
  final double punchRadius;
  final double punchPositionPercent; // Posisi vertikal takik (misal 0.65 untuk 65% dari atas)

  TicketClipper({this.punchRadius = 12.0, this.punchPositionPercent = 0.65});

  @override
  Path getClip(Size size) {
    final path = Path();
    final punchY = size.height * punchPositionPercent;

    // Mulai dari sudut kiri atas
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, punchY - punchRadius);

    // Takik kanan
    path.arcToPoint(
      Offset(size.width, punchY + punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, punchY + punchRadius);

    // Takik kiri
    path.arcToPoint(
      Offset(0, punchY - punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
```

---

## 5. Komponen Kustom: Tombol Stiker ("Sticker Button")

Tombol aksi dengan border tebal dan bayangan keras khas TemuKampus:

```dart
// lib/app/theme/components/sticker_button.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class StickerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;

  const StickerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.cobalt,
    this.textColor = Colors.white,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink, // Bayangan offset hitam
        borderRadius: BorderRadius.circular(12),
      ),
      child: Transform.translate(
        offset: const Offset(-2, -2), // Efek pop-out stiker
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(color: textColor),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Komponen Kustom: Badge & Status Pill

```dart
// lib/app/theme/components/status_pill.dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

enum RegistrationStatusType {
  pendingVerification,
  needsRevision,
  confirmed,
  rejected,
  cancelled,
}

class StatusPill extends StatelessWidget {
  final RegistrationStatusType status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case RegistrationStatusType.pendingVerification:
        bg = AppColors.amberLight;
        text = AppColors.amber;
        label = 'Menunggu Verifikasi';
        icon = Icons.hourglass_top_rounded;
        break;
      case RegistrationStatusType.needsRevision:
        bg = AppColors.signal.withOpacity(0.2);
        text = AppColors.ink;
        label = 'Perlu Revisi';
        icon = Icons.edit_note_rounded;
        break;
      case RegistrationStatusType.confirmed:
        bg = AppColors.mintLight;
        text = AppColors.mintText;
        label = 'Terkonfirmasi';
        icon = Icons.check_circle_rounded;
        break;
      case RegistrationStatusType.rejected:
        bg = AppColors.dangerLight;
        text = AppColors.dangerText;
        label = 'Ditolak';
        icon = Icons.cancel_rounded;
        break;
      case RegistrationStatusType.cancelled:
        bg = AppColors.ink100;
        text = AppColors.ink500;
        label = 'Dibatalkan';
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.badge.copyWith(color: text)),
        ],
      ),
    );
  }
}
```


---

## 7. Kontrak Poster: SATU Rasio, Banyak Ukuran (4:5)

Poster acara adalah **satu berkas master** yang dikelola backend, bukan aset per platform.

| Aturan | Nilai |
|--------|-------|
| Rasio master | **4:5** (portrait) |
| Dimensi ekspor cropper panitia | **1080 × 1350** |
| Penyimpanan backend | satu kolom `events.poster_path` (WebP) + varian lebar otomatis |
| Varian web | `_800.webp`, `_1200.webp` (proporsional, tanpa crop) |
| Varian app (rencana) | `_card.webp` 600×750, `_thumb.webp` 240×300 (proporsional, tanpa crop) |

**Aturan keras untuk UI:** setiap kanvas poster di aplikasi **wajib 4:5**. Jangan memakai
16:10, 16:9, atau kotak 1:1 — poster akan terpotong 30–50% dan tampil berbeda dari website.

| Permukaan | Kanvas |
|-----------|--------|
| Grid Beranda / Jelajah | `EventGridMetrics.posterAspectRatio = 4 / 5` |
| Carousel unggulan | poster 4:5 di sisi kanan + latar poster diburamkan |
| Hero Detail Acara | poster 4:5 utuh (200×250) di atas latar diburamkan |
| Thumb list / tiket / ringkasan | 72×90 · 52×64 · 45×56 · 42×52 (semua 4:5) |

Latar diburamkan (`ImageFiltered` + scrim) dipakai untuk mengisi ruang tanpa memotong
poster — pola yang sama dengan web yang menampilkan poster di `aspect-[4/5]`.
