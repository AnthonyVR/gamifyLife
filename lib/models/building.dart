import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

// Define a Building class
class Building {
  final int? id;
  final int villageId;
  final String name;
  final String image;
  final int level;

  Building({
    this.id,
    required this.villageId,
    required this.name,
    required this.image,
    required this.level,
  });

  // Convert a Building to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'village_id': villageId,
      'name': name,
      'image': image,
      'level': level,
    };
  }

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Convert a Map to a Building
  static Building fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'],
      villageId: map['village_id'],
      name: map['name'],
      image: map['image'],
      level: map['level'],
    );
  }

  // DATABASE OPERATIONS

  static Future<void> createTable(db) async {
    await db.execute('''
      CREATE TABLE buildings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          village_id INTEGER,
          name TEXT NOT NULL,
          image TEXT NOT NULL,
          level INTEGER NOT NULL,
          FOREIGN KEY (village_id) REFERENCES villages(id)
      )
    ''');
  }

  Future<int> insertToDb() async {
    Database db = await _db;
    return await db.insert('buildings', toMap());
  }

  Future<List<Building>> getBuildingsByVillageId(int villageId) async {
    Database db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      'buildings',
      where: 'village_id = ?',
      whereArgs: [villageId],
    );

    return List.generate(maps.length, (i) => Building.fromMap(maps[i]));
  }

}
