import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/database_helper.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';

class ConversationProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final AudioService _audioService = AudioService();
  final SpeechService _speechService = SpeechService();

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  String _currentTranscription = '';
  bool _isRecording = false;
  bool _isTranscribing = false;
  String _doctorName = '';
  String _patientName = '';

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  String get currentTranscription => _currentTranscription;
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  String get doctorName => _doctorName;
  String get patientName => _patientName;

  Future<void> initialize() async {
    print('DEBUG: ConversationProvider.initialize called');
    try {
      print('DEBUG: Initializing audio service...');
      await _audioService.initializeRecorder();
      print('DEBUG: Audio service initialized');
      
      print('DEBUG: Initializing speech service...');
      await _speechService.initialize();
      print('DEBUG: Speech service initialized');
      
      print('DEBUG: Loading conversations...');
      await loadConversations();
      print('DEBUG: Conversations loaded');
      print('DEBUG: ConversationProvider initialization complete');
    } catch (e) {
      print('DEBUG: ERROR during ConversationProvider initialization: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  void setDoctorName(String name) {
    _doctorName = name;
    notifyListeners();
  }

  void setPatientName(String name) {
    _patientName = name;
    notifyListeners();
  }

  Future<void> loadConversations() async {
    _conversations = await _databaseHelper.queryAllConversations();
    notifyListeners();
  }

  Future<bool> startNewConversation() async {
    print('DEBUG: Starting new conversation...');
    print('DEBUG: Doctor name: "$_doctorName"');
    print('DEBUG: Patient name: "$_patientName"');
    
    if (_doctorName.isEmpty || _patientName.isEmpty) {
      print('DEBUG: ERROR - Doctor or patient name is empty');
      return false;
    }

    _currentConversation = Conversation(
      doctorName: _doctorName,
      patientName: _patientName,
      transcription: '',
      startTime: DateTime.now(),
    );

    _currentTranscription = '';
    notifyListeners();

    print('DEBUG: Attempting to start recording...');
    final result = await startRecording();
    print('DEBUG: Recording start result: $result');
    return result;
  }

  Future<bool> startRecording() async {
    print('DEBUG: startRecording called');
    if (_isRecording) {
      print('DEBUG: Already recording, returning false');
      return false;
    }

    print('DEBUG: Attempting to start audio recording...');
    final recordingStarted = await _audioService.startRecording();
    print('DEBUG: Audio recording started: $recordingStarted');
    
    if (recordingStarted) {
      _isRecording = true;
      print('DEBUG: Starting transcription...');
      await _startTranscription();
      notifyListeners();
    } else {
      print('DEBUG: ERROR - Audio recording failed to start');
    }
    return recordingStarted;
  }

  Future<void> _startTranscription() async {
    _isTranscribing = true;
    notifyListeners();

    await _speechService.startListening(
      onResult: (text) {
        _currentTranscription = text;
        notifyListeners();
      },
      onConfidence: (confidence) {
        // Handle confidence level if needed
      },
    );
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    await _speechService.stopListening();
    final audioPath = await _audioService.stopRecording();

    _isRecording = false;
    _isTranscribing = false;

    if (_currentConversation != null) {
      final updatedConversation = _currentConversation!.copyWith(
        transcription: _currentTranscription,
        endTime: DateTime.now(),
        audioFilePath: audioPath,
        isCompleted: true,
      );

      final id = await _databaseHelper.insert(updatedConversation);
      _currentConversation = updatedConversation.copyWith(id: id);
      
      await loadConversations();
    }

    notifyListeners();
  }

  Future<void> pauseRecording() async {
    if (_isRecording) {
      await _speechService.stopListening();
      _isTranscribing = false;
      notifyListeners();
    }
  }

  Future<void> resumeRecording() async {
    if (_isRecording && !_isTranscribing) {
      await _startTranscription();
    }
  }

  Future<void> deleteConversation(int id) async {
    await _databaseHelper.delete(id);
    await loadConversations();
  }

  Future<List<Conversation>> searchConversations(String query) async {
    return await _databaseHelper.searchConversations(query);
  }

  Future<void> playRecording(String audioPath) async {
    await _audioService.playRecording(audioPath);
  }

  Future<void> stopPlaying() async {
    await _audioService.stopPlaying();
  }

  void clearCurrentSession() {
    _currentConversation = null;
    _currentTranscription = '';
    _doctorName = '';
    _patientName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.dispose();
    super.dispose();
  }
}