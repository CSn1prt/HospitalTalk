import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';

class DatabaseHelper {
  static const _databaseName = "HospitalTalk.db";
  static const _databaseVersion = 1;
  static const table = 'conversations';

  static const columnId = 'id';
  static const columnDoctorName = 'doctorName';
  static const columnPatientName = 'patientName';
  static const columnTranscription = 'transcription';
  static const columnStartTime = 'startTime';
  static const columnEndTime = 'endTime';
  static const columnAudioFilePath = 'audioFilePath';
  static const columnIsCompleted = 'isCompleted';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
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
}