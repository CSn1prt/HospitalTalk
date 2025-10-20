import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedWords = '';
  double _confidence = 0.0;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get recognizedWords => _recognizedWords;
  double get confidence => _confidence;

  Future<void> initialize() async {
    _speech = stt.SpeechToText();
    _isAvailable = await _speech!.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
  }

  Future<bool> _requestMicrophonePermission() async {
    final permission = await Permission.microphone.request();
    return permission == PermissionStatus.granted;
  }

  Future<bool> startListening({
    required Function(String) onResult,
    Function(double)? onConfidence,
    String localeId = 'en_US',
  }) async {
    if (_speech == null || !_isAvailable || _isListening) return false;

    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) return false;

    try {
      await _speech!.listen(
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          _confidence = result.confidence;
          onResult(_recognizedWords);
          if (onConfidence != null) {
            onConfidence(_confidence);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        onSoundLevelChange: (level) {
          // Optional: handle sound level changes
        },
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      
      _isListening = true;
      return true;
    } catch (e) {
      print('Error starting speech recognition: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_speech == null || !_isListening) return;

    try {
      await _speech!.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  Future<void> cancelListening() async {
    if (_speech == null) return;

    try {
      await _speech!.cancel();
      _isListening = false;
    } catch (e) {
      print('Error canceling speech recognition: $e');
    }
  }

  Future<List<String>> getAvailableLocales() async {
    if (_speech == null || !_isAvailable) return [];

    try {
      final locales = await _speech!.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('Error getting available locales: $e');
      return [];
    }
  }

  void dispose() {
    _speech = null;
    _isListening = false;
    _isAvailable = false;
  }
}