/// Device-side services behind interfaces: photo storage and OCR. The
/// Supabase build swaps [PhotoStore] for Storage uploads; tests swap
/// [ReceiptTextReader] for canned text.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../db/ids.dart';
import '../logic/bill_parser.dart';

abstract interface class PhotoStore {
  /// Copies [sourcePath] somewhere the app owns and returns the new path.
  Future<String> keep(String sourcePath, {required String folder});
}

class LocalPhotoStore implements PhotoStore {
  @override
  Future<String> keep(String sourcePath, {required String folder}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos/$folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = '${dir.path}/${newId()}.jpg';
    await File(sourcePath).copy(target);
    return target;
  }
}

abstract interface class ReceiptTextReader {
  Future<String> read(String imagePath);
}

/// On-device Google ML Kit text recognition. Nothing is uploaded.
class MlKitReceiptTextReader implements ReceiptTextReader {
  @override
  Future<String> read(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return layoutOcrLines([
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              text: line.text,
              top: line.boundingBox.top,
              bottom: line.boundingBox.bottom,
              left: line.boundingBox.left,
            ),
      ]);
    } finally {
      await recognizer.close();
    }
  }
}

final photoStoreProvider = Provider<PhotoStore>((ref) => LocalPhotoStore());

final receiptTextReaderProvider = Provider<ReceiptTextReader>(
  (ref) => MlKitReceiptTextReader(),
);
