import 'package:habit/models/building.dart';
import 'package:habit/models/tile.dart';
import 'package:habit/models/unit.dart';
import '../services/database_helper.dart';
import 'dart:math';

import 'misc_object.dart';

class Village {
  int id;
  String name;
  int owned;
  List<Tile> tiles = [];  // A list to store the tiles associated with this village

  Village({
    required this.id,
    required this.name,
    required this.owned,
    this.tiles = const [],  // Optionally accept a list of tiles in the constructor
  });

  static Future<Village> getVillageById(int id) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query('villages', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Village.fromMap(maps.first);
    }

    throw Exception('Village with ID $id not found');
  }


  // static Future<Village?> getVillageById(int villageId) async {
  //   final db = await DatabaseHelper.instance.database;
  //
  //   // Query the database for the village with the specified ID
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     'villages',  // Assuming the table name is 'villages'
  //     where: 'id = ?',
  //     whereArgs: [villageId],
  //   );
  //
  //   // Convert the List<Map<String, dynamic>> into a Village object
  //   if (maps.isNotEmpty) {
  //     return Village(
  //       id: maps[0]['id'],
  //       name: maps[0]['name'],
  //       owned: maps[0]['owned'],
  //       // Note: The tiles list is set to its default empty list.
  //       // You would need an additional query to fill this list if necessary.
  //     );
  //   }
  //
  //   return null; // Return null if the village is not found
  // }

  Future<Map<int, Map<int, Map<String, dynamic>>>> fetchTiles() async {
    List<Map<String, dynamic>> tilesList = await this.getTiles();

    // Initializing an empty nested map structure.
    Map<int, Map<int, Map<String, dynamic>>> resultMap = {};

    // Iterate over each tile and populate the resultMap.
    for (var tile in tilesList) {
      int rowNum = tile['rowNum'];
      int columnNum = tile['columnNum'];

      if (!resultMap.containsKey(rowNum)) {
        resultMap[rowNum] = {};
      }

      resultMap[rowNum]![columnNum] = tile;
    }
    return resultMap;
  }


  static Future<void> createTable(db) async {

    await db.execute('''
      CREATE TABLE villages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          owned INTEGER
      )
    ''');
  }


  static Future<void> createInitialVillage(db) async {

    for (int i = 1; i <= 7; i++) {
      if(i != 4) {
        Tile(villageId: 1, rowNum: 8, columnNum: i, contentType: 'building', contentId: 1).insertToDb();
      }

      Tile(villageId: 1, rowNum: 0, columnNum: i, contentType: 'building', contentId: 1).insertToDb();
      Tile(villageId: 1, rowNum: i, columnNum: 0, contentType: 'building', contentId: 2).insertToDb();
      Tile(villageId: 1, rowNum: i, columnNum: 8, contentType: 'building', contentId: 2).insertToDb();
    }

    Tile(villageId: 1, rowNum: 0, columnNum: 0, contentType: 'building', contentId: 3).insertToDb();
    Tile(villageId: 1, rowNum: 0, columnNum: 8, contentType: 'building', contentId: 4).insertToDb();
    Tile(villageId: 1, rowNum: 8, columnNum: 0, contentType: 'building', contentId: 5).insertToDb();
    Tile(villageId: 1, rowNum: 8, columnNum: 8, contentType: 'building', contentId: 6).insertToDb();

    Tile(villageId: 1, rowNum: 2, columnNum: 4, contentType: 'building', contentId: 7).insertToDb(); // town_hall
    Tile(villageId: 1, rowNum: 3, columnNum: 2, contentType: 'building', contentId: 8).insertToDb(); // farm
    Tile(villageId: 1, rowNum: 3, columnNum: 6, contentType: 'building', contentId: 9).insertToDb(); // barracks

// CREATE INITIAL MISC OBJECTS
    Tile(villageId: 1, rowNum: 15, columnNum: 2, contentType: 'miscObject', contentId: 1).insertToDb(); // rock
    Tile(villageId: 1, rowNum: 10, columnNum: 1, contentType: 'miscObject', contentId: 2).insertToDb(); // rock_two
    Tile(villageId: 1, rowNum: 12, columnNum: 7, contentType: 'miscObject', contentId: 2).insertToDb(); // rock_two

    Tile(villageId: 1, rowNum: 3, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: 1, rowNum: 4, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: 1, rowNum: 5, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: 1, rowNum: 6, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: 1, rowNum: 7, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: 1, rowNum: 4, columnNum: 4, contentType: 'miscObject', contentId: 4).insertToDb(); // path_crossed
    Tile(villageId: 1, rowNum: 4, columnNum: 5, contentType: 'miscObject', contentId: 5).insertToDb(); // path_horizontal
    Tile(villageId: 1, rowNum: 4, columnNum: 3, contentType: 'miscObject', contentId: 5).insertToDb(); // path_horizontal
    Tile(villageId: 1, rowNum: 4, columnNum: 2, contentType: 'miscObject', contentId: 6).insertToDb(); // path_bottom_left_corner
    Tile(villageId: 1, rowNum: 4, columnNum: 6, contentType: 'miscObject', contentId: 7).insertToDb(); // path_bottom_right_corner



    // Add initial buildings to the buildings table
    Building(id: 1, villageId: 1, name: 'wall_horizontal', image: 'assets/village_package/structure/wall_horizontal.png', level: 1).insertToDb();
    Building(id: 2, villageId: 1, name: 'wall_vertical', image: 'assets/village_package/structure/wall_vertical.png', level: 1).insertToDb();
    Building(id: 3, villageId: 1, name: 'wall_corner_top_left', image: 'assets/village_package/structure/wall_corner_top_left.png', level: 1).insertToDb();
    Building(id: 4, villageId: 1, name: 'wall_corner_top_right', image: 'assets/village_package/structure/wall_corner_top_right.png', level: 1).insertToDb();
    Building(id: 5, villageId: 1, name: 'wall_corner_bottom_left', image: 'assets/village_package/structure/wall_corner_bottom_left.png', level: 1).insertToDb();
    Building(id: 6, villageId: 1, name: 'wall_corner_bottom_right', image: 'assets/village_package/structure/wall_corner_bottom_right.png', level: 1).insertToDb();
    Building(id: 7, villageId: 1, name: 'town_hall', image: 'assets/village_package/structure/town_center.png', level: 1).insertToDb();
    Building(id: 8, villageId: 1, name: 'farm', image: 'assets/village_package/structure/medievalStructure_19.png', level: 1).insertToDb();
    Building(id: 9, villageId: 1, name: 'barracks', image: 'assets/village_package/structure/barracks.png', level: 1).insertToDb();

    // Create initial misc objects
    MiscObject(id: 1, villageId: 1, name: 'rock', image: 'assets/village_package/environment/medievalEnvironment_07.png').insertToDb();
    MiscObject(id: 2, villageId: 1, name: 'rock_two', image: 'assets/village_package/environment/medievalEnvironment_08.png').insertToDb();
    MiscObject(id: 3, villageId: 1, name: 'path_vertical', image: 'assets/village_package/tiles/medievalTile_03.png').insertToDb();
    MiscObject(id: 4, villageId: 1, name: 'path_crossed', image: 'assets/village_package/tiles/medievalTile_05.png').insertToDb();
    MiscObject(id: 5, villageId: 1, name: 'path_horizontal', image: 'assets/village_package/tiles/medievalTile_04.png').insertToDb();
    MiscObject(id: 6, villageId: 1, name: 'path_bottom_left_corner', image: 'assets/village_package/tiles/medievalTile_31.png').insertToDb();
    MiscObject(id: 7, villageId: 1, name: 'path_bottom_right_corner', image: 'assets/village_package/tiles/medievalTile_32.png').insertToDb();


    // Add a spearman entry with reference to this village to the units table

    Unit(id: null, villageId: 1, name: "spearman", image: "assets/spearman.png", level: 0, offence: 10, defence: 10, amount: 0, cost: 50).insertToDb();
  }


  static Future<int> insertUnit(db, Unit unit) async {

    return await db.insert('units', unit.toMap());
  }

  Future<int> levelUpUnit(int id) async {
    final db = await DatabaseHelper.instance.database;

    // Retrieve the unit by its ID
    Unit unit = await Unit.getUnitById(id);

    // level it up
    return await unit.levelUp();

  }

  Future<int> addUnit(int id) async {
    final db = await DatabaseHelper.instance.database;

    // Retrieve the unit by its ID
    Unit unit = await Unit.getUnitById(id);

    // level it up
    return await unit.addToAmount();

  }


  static Future<int> insertVillage(db, Village village) async {

    return await db.insert('villages', village.toMap());
  }


  Future<List<Map<String, dynamic>>> getTiles() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.id AS tileId,
        t.row_num AS rowNum,
        t.column_num AS columnNum,
        t.content_type AS contentType,
        t.content_id AS contentId,
        CASE
          WHEN t.content_type = 'building' THEN b.name
          WHEN t.content_type = 'unit' THEN u.name
          WHEN t.content_type = 'miscObject' THEN m.name
          ELSE null
        END AS objectName,
        CASE
          WHEN t.content_type = 'building' THEN b.image
          WHEN t.content_type = 'unit' THEN u.image
          WHEN t.content_type = 'miscObject' THEN m.image
          ELSE NULL
        END AS imagePath
      FROM tiles t
      LEFT JOIN buildings b ON t.content_type = 'building' AND t.content_id = b.id
      LEFT JOIN units u ON t.content_type = 'unit' AND t.content_id = u.id
      LEFT JOIN misc_objects m ON t.content_type = 'miscObject' AND t.content_id = m.id;
  ''');

    //print('printing maps');
    //print(maps);

    return maps;
  }


  // Extract a Village object from a Map object
  factory Village.fromMap(Map<String, dynamic> map) {
    return Village(
      id: map['id'],
      name: map['name'],
      owned: map['owned'],
    );
  }


  // Convert a Village object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owned': owned,
    };
  }


  Future<int?> getCapacity() async {

    final db = await DatabaseHelper.instance.database;

    // Query the buildings table for the farm level associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT level 
    FROM buildings 
    WHERE village_id = ? AND name = 'farm'
  ''', [id]);

    int level = maps.first['level'];
    print(level);

    int capacity = 1 + (pow(2.11, pow(level, 0.5))).toInt();


    // Check if the result is not empty and return the level
    if (maps.isNotEmpty) {
      return capacity;
    }
    return null; // Return null if no such building found
  }


  Future<int?> getPopulation() async {
    final db = await DatabaseHelper.instance.database;

    // Query the tiles table for the count of units associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT COUNT(*) as unit_count
    FROM tiles
    WHERE village_id = ? AND content_type = 'unit'
  ''', [id]);

    // Check if the result is not empty and return the count
    if (maps.isNotEmpty && maps.first['unit_count'] != null) {
      return maps.first['unit_count'] as int;
    }
    return null; // Return null if no such units found
  }


  Future<void> addTile(Tile tile) async {
    final db = await DatabaseHelper.instance.database;

    // Setting the villageId of the tile before inserting it
    tile.villageId = id;

    // Convert the Tile object to a map (assuming you have a toMap() function in the Tile class)
    Map<String, dynamic> tileMap = tile.toMap();

    // Insert the tile into the tiles table
    await db.insert('tiles', tileMap);
  }


  Future<List<Unit>> getUnits() async {
    final db = await DatabaseHelper.instance.database;

    // Query the tiles table for the units associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * 
    FROM units
    WHERE village_id = ?
  ''', [id]);

    if (maps.isEmpty) {
      throw Exception('No units found for village with ID $id');
    }

    return List.generate(maps.length, (i) {
      return Unit(
        id: maps[i]['id'],
        name: maps[i]['name'],
        cost: maps[i]['cost'],
        offence: maps[i]['offence'],
        defence: maps[i]['defence'],
        level: maps[i]['level'],
        villageId: maps[i]['village_id'],
        image: maps[i]['image'],
        amount: maps[i]['amount'],
      );
    });
  }

}
