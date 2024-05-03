import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import '/services/database_helper.dart';

class Settings {
  int? id;
  int villageSpawnFrequency;
  int buildingLevelUpFrequency;
  int unitCreationFrequency;
  int unitTrainingFrequency;
  int attackFrequency;
  double costMultiplier;

  Settings({
    this.id,
    required this.villageSpawnFrequency,
    required this.buildingLevelUpFrequency,
    required this.unitCreationFrequency,
    required this.unitTrainingFrequency,
    required this.attackFrequency,
    required this.costMultiplier,
  });

  Settings.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        villageSpawnFrequency = map['villageSpawnFrequency'],
        buildingLevelUpFrequency = map['buildingLevelUpFrequency'],
        unitCreationFrequency = map['unitCreationFrequency'],
        unitTrainingFrequency = map['unitTrainingFrequency'],
        attackFrequency = map['attackFrequency'],
        costMultiplier = map['costMultiplier'].toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'villageSpawnFrequency': villageSpawnFrequency,
      'buildingLevelUpFrequency': buildingLevelUpFrequency,
      'unitCreationFrequency': unitCreationFrequency,
      'unitTrainingFrequency': unitTrainingFrequency,
      'attackFrequency': attackFrequency,
      'costMultiplier': costMultiplier,
    };
  }

  static Future<void> createTable(db) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        villageSpawnFrequency INTEGER NOT NULL,
        buildingLevelUpFrequency INTEGER NOT NULL,
        unitCreationFrequency INTEGER NOT NULL,
        unitTrainingFrequency INTEGER NOT NULL,
        attackFrequency INTEGER NOT NULL,
        costMultiplier REAL NOT NULL
        )
    ''');
  }

  Future<int> insertToDb(Database db) async {

    print("settings inserted into db");

    return await db.insert('settings', toMap());
  }


  Future<void> updateSettings() async {
    Database db = await DatabaseHelper.instance.database;
    await db.update('settings', toMap(), where: 'id = ?', whereArgs: [id]);
  }


  static Future<Settings> getSettingsFromDB(Database db) async {

    final result = await db.query('settings', limit: 1);
    return Settings.fromMap(result.first);
  }

}
