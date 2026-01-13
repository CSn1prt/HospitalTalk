import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> initializeRecorder() async {
    print('DEBUG: Initializing AudioService...');
    print('DEBUG: Platform: ${kIsWeb ? 'Web' : 'Native'}');
    
    if (kIsWeb) {
      print('DEBUG: Web platform detected - skipping Flutter Sound initialization');
      print('DEBUG: Web audio recording will use browser MediaRecorder API');
      // On web, we'll use browser's MediaRecorder API instead of Flutter Sound
      // For now, just mark as initialized
      return;
    }
    
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();
      print('DEBUG: Created recorder and player instances');

      print('DEBUG: Opening recorder...');
      await _recorder!.openRecorder();
      print('DEBUG: Opening player...');
      await _player!.openPlayer();
      print('DEBUG: Recorder and player opened successfully');

      print('DEBUG: Requesting initial permissions...');
      final hasPermission = await _requestPermissions();
      print('DEBUG: Initial permission result: $hasPermission');
    } catch (e) {
      print('DEBUG: ERROR during initialization: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> dispose() async {
    print('DEBUG: Disposing AudioService...');
    if (kIsWeb) {
      print('DEBUG: Web platform - no Flutter Sound cleanup needed');
      return;
    }
    
    try {
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
      _recorder = null;
      _player = null;
      print('DEBUG: AudioService disposed successfully');
    } catch (e) {
      print('DEBUG: Error during disposal: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    print('DEBUG: Requesting permissions...');
    print('DEBUG: Platform: ${kIsWeb ? 'Web' : 'Native'}');
    
    if (kIsWeb) {
      print('DEBUG: Web platform - permissions handled by browser');
      // On web, permissions are handled by the browser when MediaRecorder is used
      return true;
    }
    
    final microphonePermission = await Permission.microphone.request();
    print('DEBUG: Microphone permission: $microphonePermission');
    
    // For Android 13+ (API 33+), we don't need storage permission for app's own documents directory
    // Only check microphone permission which is required for recording
    return microphonePermission == PermissionStatus.granted;
  }

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(path.join(directory.path, 'recordings'));
    
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(recordingsDir.path, 'recording_$timestamp.aac');
  }

  Future<bool> startRecording() async {
    print('DEBUG: AudioService.startRecording called');
    print('DEBUG: Platform: ${kIsWeb ? 'Web' : 'Native'}');
    print('DEBUG: Already recording? $_isRecording');
    
    if (_isRecording) {
      print('DEBUG: Cannot start - already recording');
      return false;
    }

    if (kIsWeb) {
      print('DEBUG: Starting web audio recording (simulation)');
      // For web, we'll simulate recording for now
      // In a real implementation, you'd use dart:html MediaRecorder
      _isRecording = true;
      _currentRecordingPath = 'web_recording_${DateTime.now().millisecondsSinceEpoch}.webm';
      print('DEBUG: Web recording started (simulated)');
      return true;
    }

    print('DEBUG: Recorder null? ${_recorder == null}');
    if (_recorder == null) {
      print('DEBUG: Cannot start - recorder null');
      return false;
    }

    try {
      print('DEBUG: Requesting permissions...');
      final hasPermission = await _requestPermissions();
      print('DEBUG: Has permission: $hasPermission');
      if (!hasPermission) {
        print('DEBUG: ERROR - Permission denied');
        return false;
      }

      print('DEBUG: Getting recording path...');
      _currentRecordingPath = await _getRecordingPath();
      print('DEBUG: Recording path: $_currentRecordingPath');
      
      print('DEBUG: Starting Flutter Sound recorder...');
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      print('DEBUG: Recording started successfully');
      return true;
    } catch (e) {
      print('DEBUG: ERROR starting recording: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    print('DEBUG: AudioService.stopRecording called');
    print('DEBUG: Platform: ${kIsWeb ? 'Web' : 'Native'}');
    print('DEBUG: Currently recording? $_isRecording');
    
    if (!_isRecording) {
      print('DEBUG: Not recording, nothing to stop');
      return null;
    }

    if (kIsWeb) {
      print('DEBUG: Stopping web recording (simulation)');
      _isRecording = false;
      return _currentRecordingPath;
    }

    if (_recorder == null) {
      print('DEBUG: Recorder is null, cannot stop');
      return null;
    }

    try {
      print('DEBUG: Stopping Flutter Sound recorder...');
      await _recorder!.stopRecorder();
      _isRecording = false;
      print('DEBUG: Recording stopped successfully');
      return _currentRecordingPath;
    } catch (e) {
      print('DEBUG: Error stopping recording: $e');
      return null;
    }
  }

  Future<bool> playRecording(String filePath) async {
    if (_player == null || _isPlaying) return false;

    try {
      await _player!.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
      );
      _isPlaying = true;
      return true;
    } catch (e) {
      print('Error playing recording: $e');
      return false;
    }
  }

  Future<void> stopPlaying() async {
    if (_player == null || !_isPlaying) return;

    try {
      await _player!.stopPlayer();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }
}