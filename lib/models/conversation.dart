class Conversation {
  final int? id;
  final String doctorName;
  final String patientName;
  final String transcription;
  final DateTime startTime;
  final DateTime? endTime;
  final String? audioFilePath;
  final bool isCompleted;

  Conversation({
    this.id,
    required this.doctorName,
    required this.patientName,
    required this.transcription,
    required this.startTime,
    this.endTime,
    this.audioFilePath,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'patientName': patientName,
      'transcription': transcription,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'audioFilePath': audioFilePath,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      doctorName: map['doctorName'],
      patientName: map['patientName'],
      transcription: map['transcription'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      audioFilePath: map['audioFilePath'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Conversation copyWith({
    int? id,
    String? doctorName,
    String? patientName,
    String? transcription,
    DateTime? startTime,
    DateTime? endTime,
    String? audioFilePath,
    bool? isCompleted,
  }) {
    return Conversation(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      transcription: transcription ?? this.transcription,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}