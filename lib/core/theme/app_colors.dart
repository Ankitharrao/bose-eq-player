import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF080A08); // near-black
  static const paper = Color(0xFFF4F5F0); // off-white
  static const lime = Color(0xFFC5F542); // accent

  // Tints of ink/paper for depth, so no new hues are introduced.
  static const inkRaised = Color(0xFF141714);
  static const inkLine = Color(0xFF262A25);
  static const paperMuted = Color(0xFF9A9D95);
}
