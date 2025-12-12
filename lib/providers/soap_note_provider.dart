import 'package:flutter/foundation.dart';
import '../models/soap_note.dart';
import '../services/database_helper.dart';

class SoapNoteProvider with ChangeNotifier {
  List<SoapNote> _soapNotes = [];
  bool _isLoading = false;

  List<SoapNote> get soapNotes => _soapNotes;
  bool get isLoading => _isLoading;

  Future<void> loadSoapNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _soapNotes = await DatabaseHelper.instance.queryAllSoapNotes();
    } catch (e) {
      debugPrint('Error loading SOAP notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSoapNote(SoapNote soapNote) async {
    try {
      final id = await DatabaseHelper.instance.insertSoapNote(soapNote);
      final newSoapNote = soapNote.copyWith(id: id);
      _soapNotes.insert(0, newSoapNote);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding SOAP note: $e');
      rethrow;
    }
  }

  Future<void> updateSoapNote(SoapNote soapNote) async {
    try {
      await DatabaseHelper.instance.updateSoapNote(soapNote);
      final index = _soapNotes.indexWhere((note) => note.id == soapNote.id);
      if (index != -1) {
        _soapNotes[index] = soapNote;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating SOAP note: $e');
      rethrow;
    }
  }

  Future<void> deleteSoapNote(int id) async {
    try {
      await DatabaseHelper.instance.deleteSoapNote(id);
      _soapNotes.removeWhere((note) => note.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting SOAP note: $e');
      rethrow;
    }
  }

  Future<SoapNote?> getSoapNoteByConversation(int conversationId) async {
    try {
      return await DatabaseHelper.instance.querySoapNoteByConversation(conversationId);
    } catch (e) {
      debugPrint('Error getting SOAP note by conversation: $e');
      return null;
    }
  }

  Future<List<SoapNote>> getSoapNotesByPatient(String patientId) async {
    try {
      return await DatabaseHelper.instance.querySoapNotesByPatient(patientId);
    } catch (e) {
      debugPrint('Error getting SOAP notes by patient: $e');
      return [];
    }
  }

  Future<List<SoapNote>> searchSoapNotes(String query) async {
    try {
      return await DatabaseHelper.instance.searchSoapNotes(query);
    } catch (e) {
      debugPrint('Error searching SOAP notes: $e');
      return [];
    }
  }

  List<SoapNote> getFinalizedSoapNotes() {
    return _soapNotes.where((note) => note.isFinalized).toList();
  }

  List<SoapNote> getDraftSoapNotes() {
    return _soapNotes.where((note) => !note.isFinalized).toList();
  }

  List<SoapNote> getSoapNotesByDateRange(DateTime startDate, DateTime endDate) {
    return _soapNotes.where((note) => 
      note.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
      note.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  Map<String, int> getPatientSoapNoteCounts() {
    final Map<String, int> counts = {};
    for (final note in _soapNotes) {
      counts[note.patientId] = (counts[note.patientId] ?? 0) + 1;
    }
    return counts;
  }
}