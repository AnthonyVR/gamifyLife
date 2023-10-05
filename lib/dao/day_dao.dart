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

    // Check if the table exists
    List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [DatabaseHelper.daysTable]);
    if (tables != null && tables.length > 0) {
      return await db.query(DatabaseHelper.daysTable, where: 'date = ?', whereArgs: [date]);
    }

    // Return an empty list if the table doesn't exist
    return [];
  }


  // Insert a row in the table.
  Future<int?> insertDay(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;

    // Check if the daysTable exists
    List<Map> tableExists = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [DatabaseHelper.daysTable]);

    if (tableExists.isNotEmpty) {
      return await db.insert(DatabaseHelper.daysTable, row);
    }

    // Return null or some error indicator if the table doesn't exist
    return null;
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