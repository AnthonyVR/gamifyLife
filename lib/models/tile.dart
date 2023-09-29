import 'package:habit/models/unit.dart';
import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

// Define a Tile class
class Tile {
  final int? id;
  int? villageId;
  int rowNum;
  int columnNum;
  final String contentType;  // 'unit', 'building', or 'misc_object'
  final int contentId;

  Tile({
    this.id,
    this.villageId,
    required this.rowNum,
    required this.columnNum,
    required this.contentType,
    required this.contentId,
  });

  // Convert a Tile to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'village_id': villageId,
      'row_num': rowNum,
      'column_num': columnNum,
      'content_type': contentType,
      'content_id': contentId,
    };
  }

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Convert a Map to a Tile
  static Tile fromMap(Map<String, dynamic> map) {
    return Tile(
      id: map['id'],
      villageId: map['village_id'],
      rowNum: map['row_num'],
      columnNum: map['column_num'],
      contentType: map['content_type'],
      contentId: map['content_id'],
    );
  }

  // DATABASE OPERATIONS

  static Future<void> createTable(db) async {

    await db.execute('''
      CREATE TABLE tiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          village_id INTEGER,
          row_num INTEGER,
          column_num INTEGER,
          content_type TEXT,
          content_id INTEGER,
          FOREIGN KEY (village_id) REFERENCES villages(id)
      )
    ''');
  }

  Future<List<Tile>> getTilesByVillageId(int villageId) async {
    Database db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      'tiles',
      where: 'village_id = ?',
      whereArgs: [villageId],
    );

    return List.generate(maps.length, (i) => Tile.fromMap(maps[i]));
  }

  Future<int> insertToDb() async {
    Database db = await _db;

    return await db.insert('tiles', toMap());
  }
}


