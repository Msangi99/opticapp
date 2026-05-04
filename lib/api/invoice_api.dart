import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'client.dart';

/// Result of saving a receipt PDF locally.
class InvoiceSaveResult {
  InvoiceSaveResult({
    required this.path,
    required this.filename,
    required this.savedToPublicDownloads,
    this.publicPath,
  });

  final String path;
  final String filename;
  final bool savedToPublicDownloads;

  /// When [savedToPublicDownloads] is true, same file under public Download (Android).
  final String? publicPath;
}

/// Downloads a PDF invoice/receipt from the API (binary body) and stores it where the user can find it.
Future<InvoiceSaveResult> downloadInvoicePdf({
  required String endpoint,
  required String fallbackFilename,
}) async {
  final res = await apiGet(endpoint);
  if (res.statusCode != 200) {
    String? apiMessage;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map && decoded['message'] != null) {
        apiMessage = decoded['message'].toString();
      }
    } catch (_) {}
    throw Exception(apiMessage ?? 'Failed to download invoice.');
  }

  final filename =
      _extractFilename(res.headers['content-disposition']) ?? fallbackFilename;
  final safe = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  final baseDir = await getApplicationDocumentsDirectory();
  final file = File(p.join(baseDir.path, safe));
  await file.writeAsBytes(res.bodyBytes, flush: true);

  String? publicPath;
  var savedPublic = false;
  if (!kIsWeb && Platform.isAndroid) {
    final publicDownload = Directory('/storage/emulated/0/Download');
    try {
      if (await publicDownload.exists()) {
        publicPath = p.join(publicDownload.path, safe);
        await File(publicPath).writeAsBytes(res.bodyBytes, flush: true);
        savedPublic = true;
      }
    } catch (_) {
      publicPath = null;
      savedPublic = false;
    }
  }

  return InvoiceSaveResult(
    path: file.path,
    filename: safe,
    savedToPublicDownloads: savedPublic,
    publicPath: publicPath,
  );
}

/// Saves the PDF, then either notifies about public Downloads or opens the system share sheet so the user can save to Files / Drive.
Future<void> downloadReceiptAndNotify(
  BuildContext context, {
  required String endpoint,
  required String fallbackFilename,
}) async {
  final result = await downloadInvoicePdf(
    endpoint: endpoint,
    fallbackFilename: fallbackFilename,
  );
  if (!context.mounted) return;

  if (result.savedToPublicDownloads && result.publicPath != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Receipt saved to Downloads: ${result.filename}',
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => openDownloadedFile(result.publicPath!),
        ),
      ),
    );
    return;
  }

  try {
    await Share.shareXFiles(
      [
        XFile(
          result.path,
          mimeType: 'application/pdf',
          name: result.filename,
        ),
      ],
      text: 'Receipt — save to Downloads or Files from the share menu.',
    );
  } catch (_) {
    await openDownloadedFile(result.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt saved as ${result.filename}. Use Open to view it.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => openDownloadedFile(result.path),
        ),
      ),
    );
  }
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
