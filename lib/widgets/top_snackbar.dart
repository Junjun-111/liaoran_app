import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

SnackBar buildTopSnackBar(
  String message,
  double screenHeight, {
  double screenWidth = 360,
}) {
  final bottomMargin =
      (screenHeight - 139).clamp(0.0, double.infinity).toDouble();
  final maxWidth = math.max(0.0, screenWidth - 36);
  final maxTextWidth = math.max(80.0, maxWidth - 62);
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.only(bottom: bottomMargin),
    padding: EdgeInsets.zero,
    duration: const Duration(seconds: 2),
    content: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5DDBA0), Color(0xFF2BAF74)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTextWidth),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showTopSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final size = MediaQuery.sizeOf(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    buildTopSnackBar(
      message,
      size.height,
      screenWidth: size.width,
    ),
  );
}
