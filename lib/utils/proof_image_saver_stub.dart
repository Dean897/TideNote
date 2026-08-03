import 'dart:typed_data';

Future<String> saveProofImage(
  Uint8List bytes, {
  required String fileName,
}) async {
  throw UnsupportedError('Saving proof images is not supported on this platform.');
}