import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileImageViewerPage extends StatelessWidget {
  const ProfileImageViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments as Map?) ?? const {};
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String title = (args['title']?.toString().trim().isNotEmpty ?? false)
        ? args['title'].toString()
        : 'Profile Picture';
    final String type = args['type']?.toString() ?? 'none';
    final String value = args['value']?.toString() ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? const Color(0xFF09040F) : Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0B2E), const Color(0xFF09040F)]
                : [const Color(0xFF2B1644), Colors.black],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1,
                maxScale: 5,
                constrained: true,
                clipBehavior: Clip.hardEdge,
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Center(child: _buildImage(type, value)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String type, String value) {
    if (type == 'network' && value.isNotEmpty) {
      return Hero(
        tag: 'profile-image-view:$value',
        child: Image.network(
          value,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    if (type == 'asset' && value.isNotEmpty) {
      return Hero(
        tag: 'profile-image-view:$value',
        child: Image.asset(
          value,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    if (type == 'file' && value.isNotEmpty) {
      return Hero(
        tag: 'profile-image-view:$value',
        child: Image.file(
          File(value),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: const Icon(Icons.person, size: 110, color: Colors.purple),
    );
  }
}
