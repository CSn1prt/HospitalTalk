import 'conversation.dart';

class SoapNote {
  final int? id;
  final int conversationId;
  final String patientId;
  final String chiefComplaint;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String? vitalSigns;
  final String? allergies;
  final String? medications;
  final String? medicalHistory;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final bool isFinalized;

  SoapNote({
    this.id,
    required this.conversationId,
    required this.patientId,
    required this.chiefComplaint,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    this.vitalSigns,
    this.allergies,
    this.medications,
    this.medicalHistory,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.isFinalized = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'patientId': patientId,
      'chiefComplaint': chiefComplaint,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'vitalSigns': vitalSigns,
      'allergies': allergies,
      'medications': medications,
      'medicalHistory': medicalHistory,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'isFinalized': isFinalized ? 1 : 0,
    };
  }

  factory SoapNote.fromMap(Map<String, dynamic> map) {
    return SoapNote(
      id: map['id'],
      conversationId: map['conversationId'],
      patientId: map['patientId'],
      chiefComplaint: map['chiefComplaint'] ?? '',
      subjective: map['subjective'] ?? '',
      objective: map['objective'] ?? '',
      assessment: map['assessment'] ?? '',
      plan: map['plan'] ?? '',
      vitalSigns: map['vitalSigns'],
      allergies: map['allergies'],
      medications: map['medications'],
      medicalHistory: map['medicalHistory'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      createdBy: map['createdBy'] ?? '',
      isFinalized: map['isFinalized'] == 1,
    );
  }

  SoapNote copyWith({
    int? id,
    int? conversationId,
    String? patientId,
    String? chiefComplaint,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? vitalSigns,
    String? allergies,
    String? medications,
    String? medicalHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isFinalized,
  }) {
    return SoapNote(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      patientId: patientId ?? this.patientId,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }

  factory SoapNote.fromConversation(Conversation conversation, String doctorName) {
    return SoapNote(
      conversationId: conversation.id ?? 0,
      patientId: conversation.patientName,
      chiefComplaint: '',
      subjective: _extractSubjectiveFromTranscription(conversation.transcription),
      objective: '',
      assessment: '',
      plan: '',
      createdAt: DateTime.now(),
      createdBy: doctorName,
    );
  }

  static String _extractSubjectiveFromTranscription(String transcription) {
    if (transcription.isEmpty) return '';
    
    final lines = transcription.split('\n');
    final patientStatements = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('patient:') || 
          trimmed.toLowerCase().contains('patient said') ||
          trimmed.toLowerCase().contains('patient reports')) {
        patientStatements.add(trimmed);
      }
    }
    
    return patientStatements.isNotEmpty 
        ? patientStatements.join('\n') 
        : transcription.substring(0, transcription.length > 200 ? 200 : transcription.length);
  }
}