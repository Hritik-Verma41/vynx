import 'package:flutter/material.dart';

class VynxAlertPopup extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const VynxAlertPopup({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
          child: const Text(
            "Back to Login",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
