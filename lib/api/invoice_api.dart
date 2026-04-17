import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'client.dart';

Future<String> downloadInvoiceHtml({
  required String endpoint,
  required String fallbackFilename,
}) async {
  final res = await apiGet(endpoint);
  if (res.statusCode != 200) {
    throw Exception('Failed to download invoice.');
  }

  final downloadsDir = await getApplicationDocumentsDirectory();
  final filename =
      _extractFilename(res.headers['content-disposition']) ?? fallbackFilename;
  final safe = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${downloadsDir.path}/$safe');
  await file.writeAsBytes(res.bodyBytes, flush: true);
  return file.path;
}

Future<void> openDownloadedFile(String path) async {
  final result = await OpenFilex.open(path);
  if (result.type != ResultType.done) {
    throw Exception(
      result.message.isNotEmpty
          ? result.message
          : 'Unable to open downloaded file.',
    );
  }
}

String? _extractFilename(String? header) {
  if (header == null || header.isEmpty) return null;
  final match = RegExp(
    r'filename="?([^";]+)"?',
    caseSensitive: false,
  ).firstMatch(header);
  if (match == null) return null;
  return match.group(1);
}
