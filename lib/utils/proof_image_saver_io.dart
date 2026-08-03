import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveProofImage(
  Uint8List bytes, {
  required String fileName,
}) async {
  final directory = await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
  final safeFileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${directory.path}/$safeFileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}