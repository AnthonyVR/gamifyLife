import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';

class DatabaseHelper {
  static final _databaseName = "HabitDatabase.db";
  static final _databaseVersion = 1;

  final String habitsTable = 'habits';
  final String daysTable = 'days';
  final String habitHistoryTable = 'habit_history';

  static final columnId = '_id';
  static final columnTitle = 'title';
  static final columnReward = 'reward';

  static const columnMonday = 'monday';
  static const columnTuesday = 'tuesday';
  static const columnWednesday = "wednesday";
  static const columnThursday = "thursday";
  static const columnFriday = "friday";
  static const columnSaturday = "saturday";
  static const columnSunday = "sunday";

  static const columnHabitID = 'habit_id';
  static const columnDate = 'date';
  static const columnCount = 'count';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // open the database
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $habitsTable (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnReward INTEGER NOT NULL
          )
          ''');
  }



  // HABITS TABLE //
  Future<List<Habit>> getHabits() async {
    Database db = await instance.database;
    var res = await db.query(habitsTable);
    List<Habit> list = res.isNotEmpty ? res.map((c) => Habit.fromMap(c)).toList().cast<Habit>() : [];
    return list;
  }


  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(habitsTable, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(habitsTable);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(habitsTable, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(habitsTable, where: '$columnId = ?', whereArgs: [id]);
  }



  // DAYS TABLE //

  // Query the table for all rows where the date equals the given date.
  Future<List<Map<String, dynamic>>> queryDay(String date) async {
    Database db = await instance.database;
    return await db.query(daysTable, where: 'date = ?', whereArgs: [date]);
  }

  // Insert a row in the table.
  Future<int> insertDay(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(daysTable, row);
  }

  // Get previous date from today
  Future<String> getPreviousDate(String currentDate) async {
    print("test2");
    Database db = await instance.database;
    var res = await db.rawQuery('''
    SELECT * FROM $daysTable WHERE $columnDate < ? ORDER BY $columnDate DESC LIMIT 1
  ''', [currentDate]);

    if (res.isNotEmpty) {
      return res.first[columnDate] as String;
    } else {
      throw Exception('No previous date found in the database.');
    }
  }


  Future<String> getNextDate(String currentDate) async {
    print("test2");
    Database db = await instance.database;
    var res = await db.rawQuery('''
    SELECT * FROM $daysTable WHERE $columnDate > ? ORDER BY $columnDate ASC LIMIT 1
  ''', [currentDate]);

    if (res.isNotEmpty) {
      return res.first[columnDate] as String;
    } else {
      throw Exception('No next date found in the database.');
    }
  }




  // HABITS_HISTORY TABLE //

  Future<int> insertHabitCompletion(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(habitHistoryTable, row);
  }

  Future<List<Map<String, dynamic>>> getHabitsForToday(String date, String weekday) async {
    Database db = await instance.database;

    //String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Join habits with habit_history to check if the habit has been completed
    var res = await db.rawQuery('''
      SELECT $habitsTable.*, COUNT($habitHistoryTable.$columnHabitID) as completedCount
      FROM $habitsTable 
      LEFT JOIN $habitHistoryTable 
        ON $habitsTable.$columnId = $habitHistoryTable.$columnHabitID 
        AND $habitHistoryTable.$columnDate = ?
      WHERE $habitsTable.$weekday > 0
      GROUP BY $habitsTable.$columnId
    ''', [date]);

    return res;
  }


}
