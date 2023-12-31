import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

// Define a Unit class
class Unit {
  final int? id;
  final int villageId;
  final String name;
  final String image;
  final int cost;
  int level;
  final int offence;
  final int defence;
  final int speed;
  int amount;

  var row;

  Unit({
    this.id,
    required this.villageId,
    required this.name,
    required this.image,
    required this.cost,
    required this.level,
    required this.offence,
    required this.defence,
    required this.speed,
    required this.amount
  });


  // Convert a Unit to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'village_id': villageId,
      'name': name,
      'image': image,
      'cost': cost,
      'level': level,
      'offence': offence,
      'defence': defence,
      'speed': speed,
      'amount': amount,
    };
  }


  Future<Database> get _db async => await DatabaseHelper.instance.database;


  // Convert a Map to a Unit
  static Unit fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      villageId: map['village_id'],
      name: map['name'],
      image: map['image'],
      cost: map['cost'],
      level: map['level'],
      offence: map['offence'],
      defence: map['defence'],
      speed: map['speed'],
      amount: map['amount'],
    );
  }


  static Future<void> createTable(db) async {
    await db.execute('''
      CREATE TABLE units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          village_id INTEGER,
          name TEXT NOT NULL,
          image TEXT NOT NULL,
          cost INTEGER NOT NULL,
          level INTEGER NOT NULL,
          offence INTEGER NOT NULL,
          defence INTEGER NOT NULL,
          speed INTEGER NOT NULL,
          amount INTEGER NOT NULL,
          FOREIGN KEY (village_id) REFERENCES villages(id)
      )
    ''');
  }


  Future<int> insertToDb() async {
    Database db = await _db;

    return await db.insert('units', toMap());
  }


  Future<int> levelUp() async {
    final db = await DatabaseHelper.instance.database;

    // Increase its level by 1
    level += 1;

    // Update the unit in the database
    return await db.update(
      'units',
      toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> addToAmount() async {
    final db = await DatabaseHelper.instance.database;

    // Increase its amount by 1
    amount += 1;

    // Update the unit in the database
    return await db.update(
      'units',
      toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> removeFromAmount() async {
    final db = await DatabaseHelper.instance.database;

    // Increase its amount by 1
    amount -= 1;

    // Update the unit in the database
    return await db.update(
      'units',
      toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<Unit> getUnitById(int id) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query('units', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Unit.fromMap(maps.first);
    }

    throw Exception('Unit with ID $id not found');
  }


  Future<List<Unit>> getUnitsByVillageId(int villageId) async {
    Database db = await _db;

    final List<Map<String, dynamic>> maps = await db.query(
      'units',
      where: 'village_id = ?',
      whereArgs: [villageId],
    );

    return List.generate(maps.length, (i) => Unit.fromMap(maps[i]));
  }
}
