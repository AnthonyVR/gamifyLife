import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

// Define a MiscObject class
class MiscObject {
  final int? id;
  final int villageId;
  final String name;
  final String image;

  MiscObject({
    this.id,
    required this.villageId,
    required this.name,
    required this.image,
  });

  // Convert a MiscObject to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'village_id': villageId,
      'name': name,
      'image': image,
    };
  }

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Convert a Map to a MiscObject
  static MiscObject fromMap(Map<String, dynamic> map) {
    return MiscObject(
      id: map['id'],
      villageId: map['village_id'],
      name: map['name'],
      image: map['image'],
    );
  }

  // DATABASE OPERATIONS

  static Future<void> createTable(db) async {
    await db.execute('''
      CREATE TABLE misc_objects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          village_id INTEGER,
          name TEXT NOT NULL,
          image TEXT NOT NULL,
          FOREIGN KEY (village_id) REFERENCES villages(id)
      )
    ''');
  }

  Future<int> insertToDb() async {
    Database db = await _db;
    return await db.insert('misc_objects', toMap());
  }

  Future<List<MiscObject>> getMiscObjectsByVillageId(int villageId) async {
    Database db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      'misc_objects',
      where: 'village_id = ?',
      whereArgs: [villageId],
    );

    return List.generate(maps.length, (i) => MiscObject.fromMap(maps[i]));
  }



}
