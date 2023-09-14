import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/globals.dart';


import '../models/habit.dart';
import '../models/player.dart';


class DatabaseHelper {
  static final _databaseName = "HabitDatabase.db";
  static final _databaseVersion = 1;

  // HABITS TABLE
  static String habitsTable = 'habits';

  static final columnId = '_id';
  static final columnTitle = 'title';
  static final columnReward = 'reward';
  //


  // DAYS TABLE
  static String daysTable = 'days';

  static const columnMonday = 'monday';
  static const columnTuesday = 'tuesday';
  static const columnWednesday = "wednesday";
  static const columnThursday = "thursday";
  static const columnFriday = "friday";
  static const columnSaturday = "saturday";
  static const columnSunday = "sunday";
  static const columnCreated = "created";
  //

  // HABIT HISTORY TABLE
  static String habitHistoryTable = 'habit_history';

  static const columnHistoryID = 'id';
  static const columnHabitID = 'habit_id';
  static const columnDate = 'date';
  static const columnCount = 'count';
  //

  // PLAYER TABLE
  static String playerTable = 'player';

  static const columnPlayerId = 'id';
  static const columnLevel = 'level';
  static const columnScore = 'score';
  static const columnCoins = 'coins';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {

    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // open the database
  initDatabase() async {

    String appMode = GlobalVariables.appMode; // test | prod

    if(appMode == 'test') {
      print("App running in test mode");
      habitsTable = 'test_habits';
      daysTable = 'test_days';
      habitHistoryTable = 'test_habit_history';
    }
    else if (appMode == 'prod') {
      print("App running in production mode!");
      habitsTable = 'habits';
      daysTable = 'days';
      habitHistoryTable = 'habit_history';
    }
    else {
      print("invalid app mode");
    }

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

    await db.execute('''
          CREATE TABLE $daysTable (
            // Your columns for this table
          )
    ''');

    await db.execute('''
          CREATE TABLE $habitHistoryTable (
            // Your columns for this table
          )
    ''');

    await db.execute('''
          CREATE TABLE $playerTable (
            // Your columns for this table
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


  Future<Habit?> getHabitById(int id) async {
    Database db = await instance.database;

    var res = await db.query(habitsTable, where: "$columnId = ?", whereArgs: [id]);

    return res.isNotEmpty ? Habit.fromMap(res.first) : null;

  }


  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(habitsTable, row);
  }

  // Future<List<Map<String, dynamic>>> queryAllRows() async {
  //   Database db = await instance.database;
  //   return await db.query(habitsTable);
  // }

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

  void removeAllHabits() async {

    Database db = await instance.database;
    // Remove all data from the 'habit_history' table.
    await db.rawDelete('DELETE FROM $habitsTable');

    print('All data removed from habits table');
  }

  void removeAllHabitHistory() async {

    Database db = await instance.database;
    // Remove all data from the 'habit_history' table.
    await db.rawDelete('DELETE FROM $habitHistoryTable');

    print('All data removed from habit_history table');
  }


  Future<int> insertHabitCompletion(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(habitHistoryTable, row);
  }

  Future<List<Map<String, dynamic>>> getHabitsForToday(String date, String weekday) async {
    Database db = await instance.database;

    // Join habits with habit_history to check if the habit has been completed
    var res = await db.rawQuery('''
      SELECT $habitsTable.*, COUNT($habitHistoryTable.$columnHabitID) as completedCount,
      SUM(CASE 
          WHEN $habitHistoryTable.$columnDate IS NOT NULL THEN $habitsTable.$columnReward
          ELSE 0 
          END) as totalReward
      FROM $habitsTable 
      LEFT JOIN $habitHistoryTable 
        ON $habitsTable.$columnId = $habitHistoryTable.$columnHabitID 
        AND $habitHistoryTable.$columnDate = ?
      WHERE $habitsTable.$weekday > 0
        AND $habitsTable.$columnCreated <= ?
      GROUP BY $habitsTable.$columnId
    ''', [date, date]);


    // print resulting table for debugging
    // res.forEach((Map<String, dynamic> row) {
    //   print("current table:");
    //   print(row.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    // });

    return res;
  }

  Future<List<Map<String, dynamic>>> getHabitHistory(int id) async {
    Database db = await instance.database;

    // Join habits with habit_history to check if the habit has been completed
    var res = await db.rawQuery('''
      SELECT  date,  count(id) as amount
      FROM $habitHistoryTable
      WHERE habit_id = ?
      GROUP by date
      ORDER by date desc
    ''', [id]);

    //print resulting table for debugging
    print("current table:");
    res.forEach((Map<String, dynamic> row) {
      print(row.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    });

    return res;
  }

  Future<List<Map<String, dynamic>>> getHabitHistoryForChart(int id) async {
    Database db = await instance.database;

    // Join habits with habit_history to check if the habit has been completed
    var res = await db.rawQuery('''
      SELECT $daysTable.date, COUNT($habitHistoryTable.date) as amount
      FROM 
      $daysTable
      LEFT JOIN 
      $habitHistoryTable ON $daysTable.date = $habitHistoryTable.date AND $habitHistoryTable.habit_id = ?
      GROUP BY 
      $daysTable.date
    ''', [id]);

    // print resulting table for debugging
    print("current table from getHabitHistoryForChart()");
    res.forEach((Map<String, dynamic> row) {
      print(row.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    });

    return res;
  }

  Future<int> getTotalRewardsForToday(String date, String weekday) async {
    Database db = await instance.database;

    var res = getHabitsForToday(date, weekday);

    double totalSum = 0;
    List<Map<String, dynamic>> resList = await res;
    for (var row in resList) {
      totalSum += row['totalReward'];
    }


    return totalSum.toInt();
  }

  Future<int> undo(int id, String date) async {
    Database db = await instance.database;

    // Query the first row that matches the condition
    List<Map<String, dynamic>> result = await db.query(
      habitHistoryTable,
      where: '$columnHabitID = ? AND $columnDate = ?',
      whereArgs: [id, date],
      limit: 1,  // Only return 1 row
    );

    if (result.isNotEmpty) {
      // If a row is found, delete it
      return await db.delete(
        habitHistoryTable,
        where: '$columnHistoryID = ?',
        whereArgs: [result.first[columnHistoryID]],  // Use the id of the first row
      );
    } else {
      // No matching row found
      return 0;
    }
  }


  // PLAYER TABLE //

  // Method to get coins
  Future<Player> getPlayer() async {

    Database db = await instance.database;

    // Assuming that there's only one player and its ID is 1.
    final List<Map<String, dynamic>> maps = await db.query(playerTable,
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return Player.fromMap(maps.first);
    } else {
      throw Exception('ID not found in database');
    }
  }

  Future<int> updatePlayer(Player player) async {
    Database db = await instance.database;

    // Create a Map of column names and values.
    var row = {
      'id': player.id,
      'level': player.level,
      'score': player.score,
      'coins': player.coins,
    };

    return await db.update(
      playerTable,
      row,
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

}


