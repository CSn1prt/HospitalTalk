import 'dart:io';
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
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder!.openRecorder();
    await _player!.openPlayer();

    await _requestPermissions();
  }

  Future<void> dispose() async {
    await _recorder?.closeRecorder();
    await _player?.closePlayer();
    _recorder = null;
    _player = null;
  }

  Future<bool> _requestPermissions() async {
    final microphonePermission = await Permission.microphone.request();
    final storagePermission = await Permission.storage.request();
    
    return microphonePermission == PermissionStatus.granted &&
           storagePermission == PermissionStatus.granted;
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
    if (_recorder == null || _isRecording) return false;

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) return false;

      _currentRecordingPath = await _getRecordingPath();
      
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (_recorder == null || !_isRecording) return null;

    try {
      await _recorder!.stopRecorder();
      _isRecording = false;
      return _currentRecordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
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