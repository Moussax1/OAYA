import 'dart:typed_data';
import 'dart:io';

import 'package:file_saver/file_saver.dart';

Future<bool> downloadReceiptPdf(Uint8List bytes, String fileName) async {
  try {
    final baseName = fileName.toLowerCase().endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    String? path;

    // Prefer Save As where supported so the user explicitly picks destination.
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
      path = await FileSaver.instance.saveAs(
        name: baseName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (_isValidSavedPath(path)) {
        return true;
      }
    }

    path = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return _isValidSavedPath(path);
  } catch (_) {
    return false;
  }
}

bool _isValidSavedPath(String? path) {
  if (path == null) return false;
  final normalized = path.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  if (normalized.contains('something went wrong')) return false;
  return true;
}