import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Open a full-screen live scanner dialog.
/// Returns the first detected barcode string, or null if cancelled.
Future<String?> showBarcodeScannerDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _BarcodeScannerDialog(),
  );
}

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  late final MobileScannerController _controller;
  bool _detected = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
      if (raw.isNotEmpty) {
        _detected = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            color: const Color(0xFF232F3E),
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Scan barcode',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Toggle torch',
                  onPressed: () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scanner viewport
          SizedBox(
            height: (mq.height * 0.45).clamp(220.0, 380.0),
            width: double.infinity,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, _) => Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Camera error: ${error.errorCode.name}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              'Point camera at the barcode label. Code 128, QR, EAN supported. '
              'Tap ✕ to cancel.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
