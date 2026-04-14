import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final ctrl = Get.find<ContactsController>();
  bool _isHandling = false;

  Future<void> _handle(String token) async {
    if (_isHandling) return;
    _isHandling = true;
    final ok = await ctrl.addByQr(token);
    if (ok && mounted) Get.back();
    _isHandling = false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan QR",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1A0B2E) : Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isHandling) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null && code.trim().isNotEmpty) {
                _handle(code.trim());
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
