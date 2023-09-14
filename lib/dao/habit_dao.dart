import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';

class HabitDao {

  final DatabaseHelper dbHelper;
  HabitDao(this.dbHelper);

  Future<List<Habit>> getHabits() async {
    Database db = await dbHelper.database;
    var res = await db.query(DatabaseHelper.habitsTable);
    List<Habit> list = res.isNotEmpty ? res.map((c) => Habit.fromMap(c)).toList().cast<Habit>() : [];
    return list;
  }

  Future<Habit?> getHabitById(int id) async {
    Database db = await dbHelper.database;
    var res = await db.query(DatabaseHelper.habitsTable, where: "${DatabaseHelper.columnId} = ?", whereArgs: [id]);
    return res.isNotEmpty ? Habit.fromMap(res.first) : null;
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert(DatabaseHelper.habitsTable, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    int id = row[DatabaseHelper.columnId];
    return await db.update(DatabaseHelper.habitsTable, row, where: '${DatabaseHelper.columnId} = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await dbHelper.database;
    return await db.delete(DatabaseHelper.habitsTable, where: '${DatabaseHelper.columnId} = ?', whereArgs: [id]);
  }

  void removeAllHabits() async {
    Database db = await dbHelper.database;
    await db.rawDelete('DELETE FROM ${DatabaseHelper.habitsTable}');
  }

}