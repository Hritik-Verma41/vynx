import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vynx/pages/contacts/contacts_controller.dart';
import 'package:vynx/routes/app_routes.dart';
import 'package:vynx/widgets/vynx_alert_popup.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final ctrl = Get.find<ContactsController>();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isHandling = false;

  Future<void> _resumeScanner() async {
    _isHandling = false;
    if (!mounted) return;
    await _scannerController.start();
  }

  void _showAlert({
    required String title,
    required String message,
    required bool goToContactsAfterClose,
  }) {
    Get.dialog(
      VynxAlertPopup(
        title: title,
        message: message,
        confirmBtnText: "OK",
        onConfirm: () async {
          if (Get.isDialogOpen ?? false) Get.back();

          if (goToContactsAfterClose) {
            Get.offNamed(Routes.contacts);
          } else {
            await _resumeScanner();
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleToken(String token) async {
    if (_isHandling) return;
    _isHandling = true;

    await _scannerController.stop();
    final result = await ctrl.addByQr(token);

    switch (result.outcome) {
      case QrAddOutcome.added:
        Get.offNamed(Routes.contacts);
        return;
      case QrAddOutcome.alreadyAdded:
        _showAlert(
          title: "Already Added",
          message: result.message,
          goToContactsAfterClose: true,
        );
        return;
      case QrAddOutcome.userNotFound:
        _showAlert(
          title: "User Not Found",
          message: result.message,
          goToContactsAfterClose: false,
        );
        return;
      case QrAddOutcome.invalidQr:
        _showAlert(
          title: "Invalid QR",
          message: result.message,
          goToContactsAfterClose: false,
        );
        return;
      case QrAddOutcome.failed:
        _showAlert(
          title: "Unable to Add",
          message: result.message,
          goToContactsAfterClose: false,
        );
        return;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Contact QR",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1A0B2E) : Colors.white,
        actions: [
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isHandling) return;

              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.trim().isNotEmpty) {
                  _handleToken(raw.trim());
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Align QR inside the box",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
