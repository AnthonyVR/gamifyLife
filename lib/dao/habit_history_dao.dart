import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';

class HabitHistoryDao {

  final DatabaseHelper dbHelper;
  HabitHistoryDao(this.dbHelper);

  void removeAllHabitHistory() async {
    Database db = await dbHelper.database;
    await db.rawDelete('DELETE FROM ${DatabaseHelper.habitHistoryTable}');
  }

  Future<int> insertHabitCompletion(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert(DatabaseHelper.habitHistoryTable, row);
  }

  Future<List<Map<String, dynamic>>> getHabitsForToday(String date, String weekday) async {
    Database db = await dbHelper.database;

    // Check if both tables exist
    List<Map> habitsTableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [DatabaseHelper.habitsTable]);
    List<Map> habitHistoryTableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [DatabaseHelper.habitHistoryTable]);

    if (habitsTableExists.isNotEmpty && habitHistoryTableExists.isNotEmpty) {

      var res = await db.rawQuery('''
      SELECT ${DatabaseHelper.habitsTable}.*, COUNT(${DatabaseHelper.habitHistoryTable}.${DatabaseHelper.columnHabitID}) as completedCount,
      SUM(CASE 
          WHEN ${DatabaseHelper.habitHistoryTable}.${DatabaseHelper.columnDate} IS NOT NULL THEN ${DatabaseHelper.habitsTable}.${DatabaseHelper.columnDifficulty}
          ELSE 0 
          END) as totalDifficulty
      FROM ${DatabaseHelper.habitsTable} 
      LEFT JOIN ${DatabaseHelper.habitHistoryTable} 
        ON ${DatabaseHelper.habitsTable}.${DatabaseHelper.columnId} = ${DatabaseHelper.habitHistoryTable}.${DatabaseHelper.columnHabitID} 
        AND ${DatabaseHelper.habitHistoryTable}.${DatabaseHelper.columnDate} = ?
      WHERE ${DatabaseHelper.habitsTable}.$weekday > 0
        AND ${DatabaseHelper.habitsTable}.${DatabaseHelper.columnCreated} <= ?
      GROUP BY ${DatabaseHelper.habitsTable}.${DatabaseHelper.columnId}
    ''', [date, date]);

      // print resulting table for debugging
      // res.forEach((Map<String, dynamic> row) {
      //   print("current table:");
      //   print(row.entries.map((e) => '${e.key}: ${e.value}').join(', '));
      // });

      return res;
    }

    // Return an empty list if one or both tables don't exist
    return [];
  }


  Future<List<Map<String, dynamic>>> getHabitHistory(int id) async {
    Database db = await dbHelper.database;
    var res = await db.rawQuery('''
      SELECT  date,  count(id) as amount
      FROM ${DatabaseHelper.habitHistoryTable}
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
    Database db = await dbHelper.database;
    var res = await db.rawQuery('''
      SELECT ${DatabaseHelper.daysTable}.date, COUNT(${DatabaseHelper.habitHistoryTable}.date) as amount
      FROM 
      ${DatabaseHelper.daysTable}
      LEFT JOIN 
      ${DatabaseHelper.habitHistoryTable} ON ${DatabaseHelper.daysTable}.date = ${DatabaseHelper.habitHistoryTable}.date AND ${DatabaseHelper.habitHistoryTable}.habit_id = ?
      GROUP BY 
      ${DatabaseHelper.daysTable}.date
    ''', [id]);

    // print resulting table for debugging
    print("current table from getHabitHistoryForChart()");
    res.forEach((Map<String, dynamic> row) {
      print(row.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    });

    return res;
  }

  Future<int> getTotalDifficultysForToday(String date, String weekday) async {
    Database db = await dbHelper.database;

    var res = getHabitsForToday(date, weekday);

    double totalSum = 0;
    List<Map<String, dynamic>> resList = await res;
    for (var row in resList) {
      totalSum += row['totalDifficulty'];
    }

    return totalSum.toInt();
  }

  Future<int> undo(int id, String date) async {
    Database db = await dbHelper.database;

    // Query the first row that matches the condition
    List<Map<String, dynamic>> result = await db.query(
      DatabaseHelper.habitHistoryTable,
      where: '${DatabaseHelper.columnHabitID} = ? AND ${DatabaseHelper.columnDate} = ?',
      whereArgs: [id, date],
      limit: 1,  // Only return 1 row
    );

    if (result.isNotEmpty) {

      print("row is found");
      // If a row is found, delete it
      return await db.delete(
        DatabaseHelper.habitHistoryTable,
        where: '${DatabaseHelper.columnHistoryID} = ?',
        whereArgs: [result.first[DatabaseHelper.columnHistoryID]],  // Use the id of the first row
      );
    } else {
      // No matching row found
      return 0;
    }
  }
}
