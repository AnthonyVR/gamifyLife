import 'dart:math';

import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'settings.dart';


// Define a Unit class
class Unit {
  final int? id;
  final int villageId;
  final String name;
  final String image;
  final int initialCost;
  int cost;
  int level;
  final int initialOffence;
  final int initialDefence;
  final int initialLoot;
  int offence;
  int defence;
  final int speed;
  int loot;
  int amount;

  var row;

  Unit({
    this.id,
    required this.villageId,
    required this.name,
    required this.image,
    required this.initialCost,
    required this.cost,
    required this.level,
    required this.initialOffence,
    required this.initialDefence,
    required this.initialLoot,
    required this.offence,
    required this.defence,
    required this.speed,
    required this.loot,
    required this.amount
  });


  // Convert a Unit to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'village_id': villageId,
      'name': name,
      'image': image,
      'initial_cost': initialCost,
      'cost': cost,
      'level': level,
      'initial_offence': initialOffence,
      'initial_defence': initialDefence,
      'initial_loot': initialLoot,
      'offence': offence,
      'defence': defence,
      'speed': speed,
      'loot': loot,
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
      initialCost: map['initial_cost'],
      cost: map['cost'],
      level: map['level'],
      initialOffence: map['initial_offence'],
      initialDefence: map['initial_defence'],
      initialLoot: map['initial_loot'],
      offence: map['offence'],
      defence: map['defence'],
      speed: map['speed'],
      loot: map['loot'],
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
          initial_cost INTEGER NOT NULL,
          cost INTEGER NOT NULL,
          level INTEGER NOT NULL,
          initial_offence INTEGER NOT NULL,
          initial_defence INTEGER NOT NULL,
          initial_loot INTEGER NOT NULL,
          offence INTEGER NOT NULL,
          defence INTEGER NOT NULL,
          speed INTEGER NOT NULL,
          loot INTEGER NOT NULL,
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

    Settings? settings;
    settings = await Settings.getSettingsFromDB(db);
    final double costMultiplier = settings.costMultiplier;

    // Increase its level by 1
    level += 1;

    offence = (initialOffence * pow(costMultiplier, level -1)).round();
    defence = (initialDefence * pow(costMultiplier, level -1)).round();
    cost = (initialCost * pow(costMultiplier, level -1)).round();
    loot = (initialLoot * pow(costMultiplier, level -1)).round();

    //upgradeCost = initialCost * (costMultiplier ^ (level - <span style="color: #6897bb;">1</span>))

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

  Future<int> updateAmount(int amountToUpdate) async {
    final db = await DatabaseHelper.instance.database;

    amount = amountToUpdate;

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

  Future<int> removeMultipleFromAmount(int amountToRemove) async {
    final db = await DatabaseHelper.instance.database;

    // Increase its amount by 1
    amount -= amountToRemove;

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
