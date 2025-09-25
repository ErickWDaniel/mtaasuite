import 'package:flutter/material.dart';
import 'package:mtaasuite/services/translation_service.dart';

class FormDecorations {
  static InputDecoration textFieldDecoration({
    required String labelKey,
    required String hintKey,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return InputDecoration(
      labelText: tr(labelKey),
      hintText: tr(hintKey),
      labelStyle: const TextStyle(color: Colors.tealAccent),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static InputDecoration dropdownDecoration({
    required String labelKey,
    String? hintKey,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: tr(labelKey),
      hintText: hintKey != null ? tr(hintKey) : null,
      labelStyle: const TextStyle(color: Colors.tealAccent),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.tealAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
      ),
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.tealAccent.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.tealAccent,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    );
  }
}