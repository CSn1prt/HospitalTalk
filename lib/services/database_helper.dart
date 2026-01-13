import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';
import '../models/soap_note.dart';

class DatabaseHelper {
  static const _databaseName = "HospitalTalk.db";
  static const _databaseVersion = 2;
  static const table = 'conversations';
  static const soapTable = 'soap_notes';

  static const columnId = 'id';
  static const columnDoctorName = 'doctorName';
  static const columnPatientName = 'patientName';
  static const columnTranscription = 'transcription';
  static const columnStartTime = 'startTime';
  static const columnEndTime = 'endTime';
  static const columnAudioFilePath = 'audioFilePath';
  static const columnIsCompleted = 'isCompleted';

  static const soapColumnId = 'id';
  static const soapColumnConversationId = 'conversationId';
  static const soapColumnPatientId = 'patientId';
  static const soapColumnChiefComplaint = 'chiefComplaint';
  static const soapColumnSubjective = 'subjective';
  static const soapColumnObjective = 'objective';
  static const soapColumnAssessment = 'assessment';
  static const soapColumnPlan = 'plan';
  static const soapColumnVitalSigns = 'vitalSigns';
  static const soapColumnAllergies = 'allergies';
  static const soapColumnMedications = 'medications';
  static const soapColumnMedicalHistory = 'medicalHistory';
  static const soapColumnCreatedAt = 'createdAt';
  static const soapColumnUpdatedAt = 'updatedAt';
  static const soapColumnCreatedBy = 'createdBy';
  static const soapColumnIsFinalized = 'isFinalized';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  _initDatabase() async {
    if (kIsWeb) {
      // For web, use sqflite_common_ffi_web
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        _databaseName,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // For native platforms
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade);
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnDoctorName TEXT NOT NULL,
            $columnPatientName TEXT NOT NULL,
            $columnTranscription TEXT NOT NULL,
            $columnStartTime INTEGER NOT NULL,
            $columnEndTime INTEGER,
            $columnAudioFilePath TEXT,
            $columnIsCompleted INTEGER NOT NULL DEFAULT 0
          )
          ''');

    await db.execute('''
          CREATE TABLE $soapTable (
            $soapColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $soapColumnConversationId INTEGER NOT NULL,
            $soapColumnPatientId TEXT NOT NULL,
            $soapColumnChiefComplaint TEXT NOT NULL,
            $soapColumnSubjective TEXT NOT NULL,
            $soapColumnObjective TEXT NOT NULL,
            $soapColumnAssessment TEXT NOT NULL,
            $soapColumnPlan TEXT NOT NULL,
            $soapColumnVitalSigns TEXT,
            $soapColumnAllergies TEXT,
            $soapColumnMedications TEXT,
            $soapColumnMedicalHistory TEXT,
            $soapColumnCreatedAt INTEGER NOT NULL,
            $soapColumnUpdatedAt INTEGER,
            $soapColumnCreatedBy TEXT NOT NULL,
            $soapColumnIsFinalized INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY ($soapColumnConversationId) REFERENCES $table ($columnId) ON DELETE CASCADE
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
            CREATE TABLE $soapTable (
              $soapColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
              $soapColumnConversationId INTEGER NOT NULL,
              $soapColumnPatientId TEXT NOT NULL,
              $soapColumnChiefComplaint TEXT NOT NULL,
              $soapColumnSubjective TEXT NOT NULL,
              $soapColumnObjective TEXT NOT NULL,
              $soapColumnAssessment TEXT NOT NULL,
              $soapColumnPlan TEXT NOT NULL,
              $soapColumnVitalSigns TEXT,
              $soapColumnAllergies TEXT,
              $soapColumnMedications TEXT,
              $soapColumnMedicalHistory TEXT,
              $soapColumnCreatedAt INTEGER NOT NULL,
              $soapColumnUpdatedAt INTEGER,
              $soapColumnCreatedBy TEXT NOT NULL,
              $soapColumnIsFinalized INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY ($soapColumnConversationId) REFERENCES $table ($columnId) ON DELETE CASCADE
            )
            ''');
    }
  }

  Future<int> insert(Conversation conversation) async {
    Database db = await instance.database;
    return await db.insert(table, conversation.toMap());
  }

  Future<List<Conversation>> queryAllConversations() async {
    Database db = await instance.database;
    final maps = await db.query(table, orderBy: '$columnStartTime DESC');
    return List.generate(maps.length, (i) {
      return Conversation.fromMap(maps[i]);
    });
  }

  Future<Conversation?> queryConversation(int id) async {
    Database db = await instance.database;
    final maps = await db.query(table,
        where: '$columnId = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return Conversation.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(Conversation conversation) async {
    Database db = await instance.database;
    return await db.update(table, conversation.toMap(),
        where: '$columnId = ?', whereArgs: [conversation.id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Conversation>> searchConversations(String query) async {
    Database db = await instance.database;
    final maps = await db.query(table,
        where: '$columnDoctorName LIKE ? OR $columnPatientName LIKE ? OR $columnTranscription LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '$columnStartTime DESC');
    return List.generate(maps.length, (i) {
      return Conversation.fromMap(maps[i]);
    });
  }

  Future<int> insertSoapNote(SoapNote soapNote) async {
    Database db = await instance.database;
    return await db.insert(soapTable, soapNote.toMap());
  }

  Future<List<SoapNote>> queryAllSoapNotes() async {
    Database db = await instance.database;
    final maps = await db.query(soapTable, orderBy: '$soapColumnCreatedAt DESC');
    return List.generate(maps.length, (i) {
      return SoapNote.fromMap(maps[i]);
    });
  }

  Future<SoapNote?> querySoapNote(int id) async {
    Database db = await instance.database;
    final maps = await db.query(soapTable,
        where: '$soapColumnId = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return SoapNote.fromMap(maps.first);
    }
    return null;
  }

  Future<SoapNote?> querySoapNoteByConversation(int conversationId) async {
    Database db = await instance.database;
    final maps = await db.query(soapTable,
        where: '$soapColumnConversationId = ?', whereArgs: [conversationId], limit: 1);
    if (maps.isNotEmpty) {
      return SoapNote.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SoapNote>> querySoapNotesByPatient(String patientId) async {
    Database db = await instance.database;
    final maps = await db.query(soapTable,
        where: '$soapColumnPatientId = ?', 
        whereArgs: [patientId],
        orderBy: '$soapColumnCreatedAt DESC');
    return List.generate(maps.length, (i) {
      return SoapNote.fromMap(maps[i]);
    });
  }

  Future<int> updateSoapNote(SoapNote soapNote) async {
    Database db = await instance.database;
    return await db.update(soapTable, soapNote.toMap(),
        where: '$soapColumnId = ?', whereArgs: [soapNote.id]);
  }

  Future<int> deleteSoapNote(int id) async {
    Database db = await instance.database;
    return await db.delete(soapTable, where: '$soapColumnId = ?', whereArgs: [id]);
  }

  Future<List<SoapNote>> searchSoapNotes(String query) async {
    Database db = await instance.database;
    final maps = await db.query(soapTable,
        where: '$soapColumnPatientId LIKE ? OR $soapColumnChiefComplaint LIKE ? OR $soapColumnSubjective LIKE ? OR $soapColumnAssessment LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: '$soapColumnCreatedAt DESC');
    return List.generate(maps.length, (i) {
      return SoapNote.fromMap(maps[i]);
    });
  }
}