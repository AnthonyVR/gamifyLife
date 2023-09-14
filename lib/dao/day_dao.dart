import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';

class DayDao {

  final DatabaseHelper dbHelper;
  DayDao(this.dbHelper);

  // Query the table for all rows where the date equals the given date.
  Future<List<Map<String, dynamic>>> queryDay(String date) async {
    Database db = await dbHelper.database;
    return await db.query(DatabaseHelper.daysTable, where: 'date = ?', whereArgs: [date]);
  }

  // Insert a row in the table.
  Future<int> insertDay(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert(DatabaseHelper.daysTable, row);
  }

  // Get previous date from today
  Future<String> getPreviousDate(String currentDate) async {
    Database db = await dbHelper.database;
    var res = await db.rawQuery('''
    SELECT * FROM ${DatabaseHelper.daysTable} WHERE ${DatabaseHelper.columnDate} < ? ORDER BY ${DatabaseHelper.columnDate} DESC LIMIT 1
  ''', [currentDate]);

    if (res.isNotEmpty) {
      return res.first[DatabaseHelper.columnDate] as String;
    } else {
      throw Exception('No previous date found in the database.');
    }
  }


  Future<String> getNextDate(String currentDate) async {
    Database db = await dbHelper.database;
    var res = await db.rawQuery('''
    SELECT * FROM ${DatabaseHelper.daysTable} WHERE ${DatabaseHelper.columnDate} > ? ORDER BY ${DatabaseHelper.columnDate} ASC LIMIT 1
  ''', [currentDate]);

    if (res.isNotEmpty) {
      return res.first[DatabaseHelper.columnDate] as String;
    } else {
      throw Exception('No next date found in the database.');
    }
  }


}