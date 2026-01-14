# hospital_talk

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


 1. SOAP Note Data Model (lib/models/soap_note.dart)
    - Complete SOAP structure: Subjective, Objective, Assessment, Plan
    - Additional fields: Chief Complaint, Vital Signs, Allergies, Medications, Medical History
    - Draft/Finalized workflow with timestamps and audit trail
  2. Database Integration (lib/services/database_helper.dart)
    - New SOAP notes table with foreign key relationship to conversations
    - Database migration from v1 to v2
    - Full CRUD operations for SOAP notes
  3. User Interface
    - SOAP Note Creation/Editing Screen with form validation
    - SOAP Note List Screen with search and filtering
    - Integration with Conversation Details - create/view SOAP notes directly from conversations
    - Home Screen updated with SOAP notes access button
  4. State Management
    - New SoapNoteProvider for managing SOAP note state
    - Integrated with existing ConversationProvider
  5. Smart Features
    - Auto-populates Subjective section from conversation transcription
    - Draft vs. Finalized workflow
    - Patient history tracking
    - Search functionality across all SOAP note fields

  🚀 How to Use

  1. From Conversations: Open any conversation detail → Menu → "Create/View SOAP Note"
  2. From Home Screen: "View SOAP Notes" button to see all SOAP notes
  3. SOAP Creation: Fill out the 4 main sections (S.O.A.P) plus additional medical information
  4. Workflow: Save as draft or finalize (finalized notes become read-only)

  The implementation follows EMR standards and integrates seamlessly with your existing audio recording and
  transcription workflow. All data remains securely stored locally on the device.

  This project uses a comprehensive speech-to-text system built on Flutter with the following key technologies:

  Core Speech-to-Text Features

  Primary Library: speech_to_text package (v7.0.0) for real-time speech recognition

  Key Components:
  - Speech Service (lib/services/speech_service.dart): Handles live transcription with confidence tracking, multiple locales, and 30-second max recording sessions
  - Audio Service (lib/services/audio_service.dart): Records audio files in AAC format using flutter_sound package
  - Conversation Provider (lib/providers/conversation_provider.dart): Coordinates both audio recording and speech recognition simultaneously

  Main Features

  1. Real-time transcription with live text updates during recording
  2. Dual recording: Both audio files and text transcription are saved
  3. Offline capability using device's native speech recognition
  4. Complete workflow: Setup → Recording → Transcription → Storage → Retrieval
  5. Cross-platform support with proper permissions for Android/iOS
  6. Database integration using SQLite for storing conversations and transcriptions

  The system is designed for medical conversations, allowing doctors to record patient interactions with live speech-to-text conversion while maintaining audio backups for
  accuracy verification.
