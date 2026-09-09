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

  String? _extractCardNumber(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    // Основной формат: VSL-31471850.
    final directMatch = RegExp(
      r'VSL[-\s_]?\d{8}',
      caseSensitive: false,
    ).firstMatch(value);
    if (directMatch != null) {
      final digits = RegExp(r'\d{8}').firstMatch(directMatch.group(0)!)!.group(0)!;
      return 'VSL-$digits';
    }

    // Старый/служебный формат: VSLAST|CARD|...
    final qrMatch = RegExp(
      r'VSLAST\s*\|\s*CARD\s*\|\s*([^|\s]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (qrMatch != null) {
      final cardValue = qrMatch.group(1)!.trim().toUpperCase();
      final digitsMatch = RegExp(r'\d{8}').firstMatch(cardValue);
      if (digitsMatch != null) {
        return 'VSL-${digitsMatch.group(0)}';
      }
    }

    // QR может содержать просто номер карты.
    final digitsOnly = RegExp(r'(?<!\d)\d{8}(?!\d)').firstMatch(value);
    if (digitsOnly != null) {
      return 'VSL-${digitsOnly.group(0)}';
    }

    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      // У некоторых декодеров rawValue может быть пустым, а displayValue
      // заполнен, поэтому используем оба значения.
      final raw = (barcode.rawValue ?? barcode.displayValue)?.trim();
      if (raw == null || raw.isEmpty) continue;

      final cardNumber = _extractCardNumber(raw);
      if (cardNumber == null) continue;

      _handled = true;

      // Камера должна быть остановлена до закрытия экрана.
      await _controller.stop();

      if (!mounted) return;

      Navigator.of(context).pop(cardNumber);
      return;
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
