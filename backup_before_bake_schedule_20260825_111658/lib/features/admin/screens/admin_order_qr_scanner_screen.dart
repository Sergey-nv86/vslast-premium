import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminOrderQrScannerScreen extends StatefulWidget {
  const AdminOrderQrScannerScreen({super.key});

  @override
  State<AdminOrderQrScannerScreen> createState() =>
      _AdminOrderQrScannerScreenState();
}

class _AdminOrderQrScannerScreenState extends State<AdminOrderQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      // Формат клиентского QR:
      // VSLAST|CARD|000128
      final parts = raw.split('|');

      if (parts.length == 3 &&
          parts[0].toUpperCase() == 'VSLAST' &&
          parts[1].toUpperCase() == 'CARD' &&
          parts[2].trim().isNotEmpty) {
        _handled = true;
        _controller.stop();

        Navigator.of(context).pop(parts[2].trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.black.withValues(alpha: .45),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Сканировать QR клиента',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .60),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Наведите камеру на QR-код клиента',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Material(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(18),
                    child: IconButton(
                      onPressed: () => _controller.toggleTorch(),
                      icon: const Icon(
                        Icons.flashlight_on_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Фонарик',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
