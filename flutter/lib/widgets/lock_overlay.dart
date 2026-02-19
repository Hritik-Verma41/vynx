import 'dart:ui';
import 'package:flutter/material.dart';

class LockOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  const LockOverlay({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: isDark ? Colors.black87 : Colors.white70),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: isDark ? Colors.purple[200] : Colors.purple[700],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Vynx is Locked",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Unlock with biometrics to continue"),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Unlock Now"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
