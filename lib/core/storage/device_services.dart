/// Device-side services behind interfaces: photo storage. The Supabase
/// build swaps [PhotoStore] for Storage uploads.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../db/ids.dart';

abstract interface class PhotoStore {
  /// Copies [sourcePath] somewhere the app owns and returns the new path.
  Future<String> keep(String sourcePath, {required String folder});
}

class LocalPhotoStore implements PhotoStore {
  @override
  Future<String> keep(String sourcePath, {required String folder}) async {
    if (kIsWeb) return sourcePath;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos/$folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    final target = '${dir.path}/${newId()}.jpg';
    await File(sourcePath).copy(target);
    return target;
  }
}

final photoStoreProvider = Provider<PhotoStore>((ref) => LocalPhotoStore());
