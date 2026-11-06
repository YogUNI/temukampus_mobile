import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';

class PickedImageData {
  final XFile file;
  final Uint8List bytes;
  final int sizeInBytes;
  final String fileName;

  const PickedImageData({
    required this.file,
    required this.bytes,
    required this.sizeInBytes,
    required this.fileName,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      final kb = (sizeInBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (sizeInBytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    }
  }

  bool get isUnderLimit => sizeInBytes <= AppConstants.maxUploadSizeBytes;
}

/// Utilitas resmi untuk mengambil dan mengompres bukti transfer pembayaran.
class AppImageHelper {
  AppImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Mengambil gambar dari Galeri atau Kamera langsung
  static Future<PickedImageData?> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80, // Kompresi awal otomatis pada level kompresi JPEG 80%
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final size = bytes.lengthInBytes;

      return PickedImageData(
        file: pickedFile,
        bytes: bytes,
        sizeInBytes: size,
        fileName: pickedFile.name,
      );
    } catch (e) {
      debugPrint('[AppImageHelper] Gagal mengambil gambar: $e');
      return null;
    }
  }
}
