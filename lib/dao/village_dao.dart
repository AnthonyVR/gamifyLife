import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/village.dart';
import '../services/database_helper.dart';

class VillageDao {
  final DatabaseHelper dbHelper;
  VillageDao(this.dbHelper);

  Future<List<Village>> getVillages() async {
    Database db = await dbHelper.database;
    var res = await db.query(DatabaseHelper.villagesTable);
    List<Village> list = res.isNotEmpty ? res.map((c) => Village.fromMap(c)).toList().cast<Village>() : [];
    return list;
  }

  Future<Village?> getVillageById(int id) async {
    Database db = await dbHelper.database;
    var res = await db.query(DatabaseHelper.villagesTable, where: "${DatabaseHelper.columnId} = ?", whereArgs: [id]);
    return res.isNotEmpty ? Village.fromMap(res.first) : null;
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    return await db.insert(DatabaseHelper.villagesTable, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await dbHelper.database;
    int id = row[DatabaseHelper.columnId];
    return await db.update(DatabaseHelper.villagesTable, row, where: '${DatabaseHelper.columnId} = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await dbHelper.database;
    return await db.delete(DatabaseHelper.villagesTable, where: '${DatabaseHelper.columnId} = ?', whereArgs: [id]);
  }

  void removeAllVillages() async {
    Database db = await dbHelper.database;
    await db.rawDelete('DELETE FROM ${DatabaseHelper.villagesTable}');
  }
}
