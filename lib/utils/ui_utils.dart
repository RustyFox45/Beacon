import 'dart:io';
import 'package:flutter/material.dart';

class UiUtils {
  // Returns the correct ImageProvider based on whether the URL is a local file or network URL
  static ImageProvider? getAvatarProvider(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    } else {
      return FileImage(File(url));
    }
  }

  // Shortens a long name to First LastInitial. (e.g., "Logan Lawson" -> "Logan L.")
  static String formatShortName(String name) {
    if (name.length <= 10) return name;
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return name;
  }
}
