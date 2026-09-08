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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      // Клиентский QR может быть:
      // VSL-31471850
      // VSLAST|CARD|VSL-31471850
      // VSLAST|CARD|31471850
      String? cardNumber;

      final directMatch = RegExp(
        r'VSL-\d{8}',
        caseSensitive: false,
      ).firstMatch(raw);

      if (directMatch != null) {
        cardNumber = directMatch.group(0)!.toUpperCase();
      } else {
        final qrMatch = RegExp(
          r'^VSLAST\|CARD\|([^|\s]+)$',
          caseSensitive: false,
        ).firstMatch(raw);

        if (qrMatch != null) {
          var value = qrMatch.group(1)!.trim().toUpperCase();

          if (RegExp(r'^\d{8}$').hasMatch(value)) {
            value = 'VSL-$value';
          } else {
            final withoutDash = RegExp(
              r'^VSL(\d{8})$',
              caseSensitive: false,
            ).firstMatch(value);

            if (withoutDash != null) {
              value = 'VSL-${withoutDash.group(1)}';
            }
          }

          if (RegExp(r'^VSL-\d{8}$').hasMatch(value)) {
            cardNumber = value;
          }
        }
      }

      if (cardNumber != null) {
        _handled = true;

        // Камера должна быть остановлена до закрытия экрана.
        await _controller.stop();

        if (!mounted) return;

        Navigator.of(context).pop(cardNumber);
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
