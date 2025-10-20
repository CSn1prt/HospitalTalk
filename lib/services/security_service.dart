import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityService {
  static String generateSessionId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(255));
    return base64UrlEncode(values);
  }

  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String obfuscatePatientName(String name) {
    if (name.length <= 2) return name;
    final firstChar = name[0];
    final lastChar = name[name.length - 1];
    final middle = '*' * (name.length - 2);
    return '$firstChar$middle$lastChar';
  }

  static bool isValidInput(String input) {
    final regex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    return regex.hasMatch(input) && input.trim().isNotEmpty;
  }

  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'[<>"' + "']"), '');
  }

  static Map<String, dynamic> createSecureMetadata({
    required String doctorName,
    required String patientName,
    required DateTime timestamp,
  }) {
    return {
      'sessionId': generateSessionId(),
      'doctorHash': hashSensitiveData(doctorName),
      'patientHash': hashSensitiveData(patientName),
      'timestamp': timestamp.toIso8601String(),
      'version': '1.0',
    };
  }

  static bool validateConversationIntegrity(Map<String, dynamic> metadata) {
    final requiredKeys = ['sessionId', 'doctorHash', 'patientHash', 'timestamp'];
    return requiredKeys.every((key) => metadata.containsKey(key));
  }
}