import 'dart:convert';

import 'package:habit/models/building.dart';
import 'package:habit/models/tile.dart';
import 'package:habit/models/unit.dart';
import '../services/database_helper.dart';
import 'dart:math';

import 'misc_object.dart';

class Village {
  final int? id;
  String name;
  int owned;
  final int row;
  final int column;
  int coins;
  List<Tile> tiles = [];  // A list to store the tiles associated with this village

  Village({
    this.id,
    required this.name,
    required this.owned,
    required this.row,
    required this.column,
    required this.coins,
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

  Future<Map<int, Map<int, Map<String, dynamic>>>> fetchTiles() async {
    List<Map<String, dynamic>> tilesList = await getTiles();

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

    print("resultmapppp");
    print(resultMap);

    return resultMap;
  }

  static Future<void> createTable(db) async {

    await db.execute('''
      CREATE TABLE villages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          owned INTEGER,
          row INTEGER,
          column INTEGER,
          coins INTEGER
      )
    ''');
  }


  // Extract a Village object from a Map object
  factory Village.fromMap(Map<String, dynamic> map) {
    return Village(
      id: map['id'],
      name: map['name'],
      owned: map['owned'],
      row: map['row'],
      column: map['column'],
      coins: map['coins']
    );
  }

  // Convert a Village object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owned': owned,
      'row': row,
      'column': column,
      'coins': coins
    };
  }

  static Future<void> createInitialVillage(db, int villageId) async {

    print("Running function createInitialVillage() for village id ${villageId}");

    //await db.execute("DELETE FROM tiles");

    for (int i = 1; i <= 7; i++) {
      if(i != 4) {
        Tile(villageId: villageId, rowNum: 8, columnNum: i, contentType: 'building', contentId: 1).insertToDb();
      }

      Tile(villageId: villageId, rowNum: 0, columnNum: i, contentType: 'building', contentId: 1).insertToDb();
      Tile(villageId: villageId, rowNum: i, columnNum: 0, contentType: 'building', contentId: 2).insertToDb();
      Tile(villageId: villageId, rowNum: i, columnNum: 8, contentType: 'building', contentId: 2).insertToDb();
    }

    Tile(villageId: villageId, rowNum: 0, columnNum: 0, contentType: 'building', contentId: 3).insertToDb();
    Tile(villageId: villageId, rowNum: 0, columnNum: 8, contentType: 'building', contentId: 4).insertToDb();
    Tile(villageId: villageId, rowNum: 8, columnNum: 0, contentType: 'building', contentId: 5).insertToDb();
    Tile(villageId: villageId, rowNum: 8, columnNum: 8, contentType: 'building', contentId: 6).insertToDb();

    Tile(villageId: villageId, rowNum: 2, columnNum: 4, contentType: 'building', contentId: 7).insertToDb(); // town_hall
    Tile(villageId: villageId, rowNum: 3, columnNum: 2, contentType: 'building', contentId: 8).insertToDb(); // farm
    Tile(villageId: villageId, rowNum: 3, columnNum: 6, contentType: 'building', contentId: 9).insertToDb(); // barracks

// CREATE INITIAL MISC OBJECTS
    Tile(villageId: villageId, rowNum: 15, columnNum: 2, contentType: 'miscObject', contentId: 1).insertToDb(); // rock
    Tile(villageId: villageId, rowNum: 10, columnNum: 1, contentType: 'miscObject', contentId: 2).insertToDb(); // rock_two
    Tile(villageId: villageId, rowNum: 12, columnNum: 7, contentType: 'miscObject', contentId: 2).insertToDb(); // rock_two

    Tile(villageId: villageId, rowNum: 3, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: villageId, rowNum: 4, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: villageId, rowNum: 5, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: villageId, rowNum: 6, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: villageId, rowNum: 7, columnNum: 4, contentType: 'miscObject', contentId: 3).insertToDb(); // path_vertical
    Tile(villageId: villageId, rowNum: 4, columnNum: 4, contentType: 'miscObject', contentId: 4).insertToDb(); // path_crossed
    Tile(villageId: villageId, rowNum: 4, columnNum: 5, contentType: 'miscObject', contentId: 5).insertToDb(); // path_horizontal
    Tile(villageId: villageId, rowNum: 4, columnNum: 3, contentType: 'miscObject', contentId: 5).insertToDb(); // path_horizontal
    Tile(villageId: villageId, rowNum: 4, columnNum: 2, contentType: 'miscObject', contentId: 6).insertToDb(); // path_bottom_left_corner
    Tile(villageId: villageId, rowNum: 4, columnNum: 6, contentType: 'miscObject', contentId: 7).insertToDb(); // path_bottom_right_corner


    // Add initial buildings to the buildings table
    Building(villageId: villageId, name: 'wall_horizontal', image: 'assets/village_package/structure/wall_horizontal.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'wall_vertical', image: 'assets/village_package/structure/wall_vertical.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'wall_corner_top_left', image: 'assets/village_package/structure/wall_corner_top_left.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'wall_corner_top_right', image: 'assets/village_package/structure/wall_corner_top_right.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'wall_corner_bottom_left', image: 'assets/village_package/structure/wall_corner_bottom_left.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'wall_corner_bottom_right', image: 'assets/village_package/structure/wall_corner_bottom_right.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'town_hall', image: 'assets/village_package/structure/town_center.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'farm', image: 'assets/village_package/structure/medievalStructure_19.png', level: 1).insertToDb();
    Building(villageId: villageId, name: 'barracks', image: 'assets/village_package/structure/barracks.png', level: 1).insertToDb();

    // Create initial misc objects
    MiscObject(villageId: villageId, name: 'rock', image: 'assets/village_package/environment/medievalEnvironment_07.png').insertToDb();
    MiscObject(villageId: villageId, name: 'rock_two', image: 'assets/village_package/environment/medievalEnvironment_08.png').insertToDb();
    MiscObject(villageId: villageId, name: 'path_vertical', image: 'assets/village_package/tiles/medievalTile_03.png').insertToDb();
    MiscObject(villageId: villageId, name: 'path_crossed', image: 'assets/village_package/tiles/medievalTile_05.png').insertToDb();
    MiscObject(villageId: villageId, name: 'path_horizontal', image: 'assets/village_package/tiles/medievalTile_04.png').insertToDb();
    MiscObject(villageId: villageId, name: 'path_bottom_left_corner', image: 'assets/village_package/tiles/medievalTile_31.png').insertToDb();
    MiscObject(villageId: villageId, name: 'path_bottom_right_corner', image: 'assets/village_package/tiles/medievalTile_32.png').insertToDb();


    // Add units entries with reference to this village to the units table
    Unit(villageId: villageId, name: "spearman", image: "assets/spearman.png", level: 1, initialOffence: 10, initialDefence: 10, offence: 10, defence: 10, amount: 5, initialCost: 50, cost: 50, speed: 1).insertToDb();
    Unit(villageId: villageId, name: "wizard", image: "assets/wizard.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 4, initialCost: 80, cost: 80, speed: 1).insertToDb();
    Unit(villageId: villageId, name: "catapult", image: "assets/catapult.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 100, initialCost: 300, cost: 300, speed: 1).insertToDb();
    Unit(villageId: villageId, name: "king", image: "assets/king.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 1, initialCost: 1000, cost: 1000, speed: 1).insertToDb();

    // Add units to tiles for defending testing
    Tile(villageId: villageId, rowNum: 16, columnNum: 4, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 5, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 6, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 3, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 2, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 1, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 0, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 16, columnNum: 7, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 3, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 4, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 5, contentType: 'unit', contentId: 2).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 6, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 7, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner
    Tile(villageId: villageId, rowNum: 15, columnNum: 8, contentType: 'unit', contentId: 1).insertToDb(); // path_bottom_right_corner

    print("Function createInitialVillage() finished");

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

  Future<void> changeOwner(int owned) async {
    final db = await DatabaseHelper.instance.database;

    await db.rawUpdate('''
      UPDATE villages 
      SET owned = ? 
      WHERE id = ?
    ''', [owned, id]);

  }

  Future<void> changeName(String name) async {
    final db = await DatabaseHelper.instance.database;

    await db.rawUpdate('''
      UPDATE villages 
      SET name = ? 
      WHERE id = ?
    ''', [name, id]);

  }

  Future<int> addUnit(int id) async {

    // Retrieve the unit by its ID
    Unit unit = await Unit.getUnitById(id);

    // add it
    return await unit.addToAmount();

  }

  Future<int> removeUnit(int id) async {

    // Retrieve the unit by its ID
    Unit unit = await Unit.getUnitById(id);

    // add it
    return await unit.removeFromAmount();

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
      LEFT JOIN misc_objects m ON t.content_type = 'miscObject' AND t.content_id = m.id
      WHERE t.village_id = ?;
  ''', [id]);

    //print('printing maps');
    //print(maps);

    return maps;
  }

  static Future<int> getNumberOfOwnedVillages() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      *
    FROM villages
    WHERE owned = 1;
    ''');

    List<Village> villages = maps.map((map) => Village.fromMap(map)).toList();

    return villages.length;
  }

  Future<int?> getBuildingLevel(String buildingName) async {

    final db = await DatabaseHelper.instance.database;

    // Query the buildings table for the farm level associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT level 
    FROM buildings 
    WHERE village_id = ? AND name = ?
  ''', [id, buildingName]);

    int level = maps.first['level'];

    return level;
  }

  Future<void> upgradeBuildingLevel(String buildingName) async {
    final db = await DatabaseHelper.instance.database;

    // First, retrieve the current level.
    int? currentLevel = await getBuildingLevel(buildingName);

    // Check if currentLevel is not null (i.e., a valid level was found).
    if (currentLevel != null) {
      // Update the level in the database.
      await db.rawUpdate('''
      UPDATE buildings 
      SET level = ? 
      WHERE village_id = ? AND name = ?
    ''', [currentLevel + 1, id, buildingName]);
    } else {
      // Handle error: for example, building not found for the given villageId and buildingName.
      throw Exception('Building $buildingName not found for villageId $id');
    }
  }

  Future<void> updateBuildingLevel(String buildingName, int level) async {
    final db = await DatabaseHelper.instance.database;

   await db.rawUpdate('''
      UPDATE buildings 
      SET level = ? 
      WHERE village_id = ? AND name = ?
    ''', [level, id, buildingName]);
  }

  Future<int?> getCapacity() async {

    int? level = await getBuildingLevel('farm');
    int capacity = (pow(2.5, pow(level!, 0.5))).round();

    return capacity;

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

    // remove from amount in units table if it's a unit
    if(tile.contentType == 'unit'){
      removeUnit(tile.contentId);
    }

  }

  Future<void> removeTile(Tile tile) async {
    final db = await DatabaseHelper.instance.database;

    // Assuming each Tile has a unique ID, use it to delete the tile from the database.
    // If you don't have an ID, you might use other unique fields like a combination of row_num and column_num.

    await db.delete(
      'tiles',
      where: 'id = ?',
      whereArgs: [tile.id],
    );

    // add to amount in units table if it's a unit
    if(tile.contentType == 'unit'){
      addUnit(tile.contentId);
    }
  }

  // move a tile to another location (row and column) on the map
  Future<void> moveTile(Tile tile, int newRow, int newColumn) async {
    final db = await DatabaseHelper.instance.database;

    // Update the tile's properties in memory
    tile.rowNum = newRow;
    tile.columnNum = newColumn;

    // Convert the updated Tile object to a map (assuming you have a toMap() function in the Tile class)
    Map<String, dynamic> updatedTileMap = tile.toMap();

    // Update the tile in the database using its ID as the reference
    await db.update(
      'tiles',
      updatedTileMap,
      where: 'id = ?',
      whereArgs: [tile.id],
    );
  }

  Future<List<Unit>> getUnits() async {
    final db = await DatabaseHelper.instance.database;

    // Query the units table for the units associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * 
    FROM units
    WHERE village_id = ?
  ''', [id]);

    if (maps.isEmpty) {
      return [];
      //throw Exception('No units found for village with ID $id');
    }

    // Use fromMap to create a list of Unit objects
    return maps.map((map) => Unit.fromMap(map)).toList();
  }

  Future<List<Unit>> getAvailableUnits() async {
    final db = await DatabaseHelper.instance.database;

    // Query the units table for the units associated with the given villageId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * 
    FROM units
    WHERE village_id = ?
    AND amount > 0
  ''', [id]);

    if (maps.isEmpty) {
      return [];
      //throw Exception('No units found for village with ID $id');
    }

    // Use fromMap to create a list of Unit objects
    return maps.map((map) => Unit.fromMap(map)).toList();
  }

  // Units that are sent out for attack (either by player or enemy) are removed from the amount in the units table from the moment the attack starts.
  // This function looks at the attacks table and calculates whether there are units that should already have returned to the village and can again be added to the amount.
  static Future<void> updateUnitsInTransit() async {
    final db = await DatabaseHelper.instance.database;

    // Step 1: Fetch the relevant attacks
    final List<Map<String, dynamic>> attackMaps = await db.rawQuery('''
    SELECT * 
    FROM attacks
    WHERE completed = 1 AND returned_at <= ?
  ''', [DateTime.now().toIso8601String()]);  // assuming `returned_at` is stored as a string in ISO format

    for (var attack in attackMaps) {
      // Deserialize the source_units_after column (assuming it's stored as a JSON string)
      List<Map<String, dynamic>> sourceUnitsAfter = (json.decode(attack['source_units_after']) as List).cast<Map<String, dynamic>>();

      print("printing sourceUnitsAfter");
      print(sourceUnitsAfter);
      // Step 2 and 3: For each unit, update the amount in the units table
      for (var unitData in sourceUnitsAfter) {
        int unitId = unitData['unit']['id'];
        int amountToAdd = unitData['amount'];

        await db.rawUpdate('''
        UPDATE units
        SET amount = amount + ?
        WHERE id = ?
      ''', [amountToAdd, unitId]);
      }

      // update the attack as "completed 2"
      await db.update('attacks', {'completed': 2}, where: 'id = ?', whereArgs: [attack['id']]);
    }
  }

  // similar to the above updateUnitsInTransit() but updates the units that are defending the village from the moment the attack has arrived in the defending village.
  static Future<void> updateUnitsDefending() async {
    final db = await DatabaseHelper.instance.database;

    // Step 1: Fetch the relevant attacks
    final List<Map<String, dynamic>> attackMaps = await db.rawQuery('''
    SELECT * 
    FROM attacks
    WHERE completed = 0 AND arrived_at <= ? AND owned = 1
  ''', [DateTime.now().toIso8601String()]);  // assuming `returned_at` is stored as a string in ISO format

    for (var attack in attackMaps) {
      // Deserialize the source_units_after column (assuming it's stored as a JSON string)
      List<Map<String, dynamic>> destinationUnitsAfter = (json.decode(attack['destination_units_after']) as List).cast<Map<String, dynamic>>();

      print("printing sourceUnitsAfter");
      print(destinationUnitsAfter);
      // Step 2 and 3: For each unit, update the amount in the units table
      for (var unitData in destinationUnitsAfter) {
        int unitId = unitData['unit']['id'];
        int amountToUpdate = unitData['amount'];

        print('updating the amount in this village to');
        print(amountToUpdate);

        await db.rawUpdate('''
        UPDATE units
        SET amount = ?
        WHERE id = ?
      ''', [amountToUpdate, unitId]);
      }

      // update the attack as "completed 1"
      await db.update('attacks', {'completed': 1}, where: 'id = ?', whereArgs: [attack['id']]);
    }
  }



  // Gets the units that are placed in the village with their row numbers
  Future<List<Unit>> getDefendingUnits() async {
    final db = await DatabaseHelper.instance.database;

    // Perform a join query between the 'units' and 'tiles' tables
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT units.*, tiles.row_num
    FROM tiles
    JOIN units ON tiles.content_id = units.id
    WHERE tiles.village_id = ? AND tiles.content_type = 'unit'
  ''', [id]); // assuming `this.id` refers to the current village ID

    if (maps.isEmpty) {
      print("no defending units found");
      return [];
      //throw Exception('No units found for village with ID $id');
    }

    // Construct list of Unit objects with additional 'row' information
    return List.generate(maps.length, (i) {
      var unitMap = maps[i];
      // Extract 'row'
      var row = unitMap['row_num'];

      // Create a new map from unitMap that doesn't include 'row'
      var unitMapWithoutRow = Map<String, dynamic>.from(unitMap)..remove('row_num');

      // Create a Unit object using fromMap
      var unit = Unit.fromMap(unitMapWithoutRow);
      // Assuming Unit class has a setter method for 'row' or it's a publicly accessible field
      unit.row = row;

      return unit;
    });
  }


  Future<Tile?> getTileByRowAndColumn(int row, int column) async {
    final db = await DatabaseHelper.instance.database;

    List<Map<String, dynamic>> results = await db.query(
      'tiles',
      where: 'row_num = ? AND column_num = ?',
      whereArgs: [row, column],
    );

    // If no results were found, return null
    if (results.isEmpty) {
      return null;
    }

    // Assuming Tile has a factory method fromMap to create an instance from a Map
    return Tile.fromMap(results.first);
  }

  Future<void> placeTileInVillage(int id, int row, int column, String type) async {

    Tile tile = Tile(rowNum: row, columnNum: column, contentType: type, contentId: id);

    addTile(tile);
  }

  static Future<List<Map<String, dynamic>>> getVillages() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        id AS id,
        name as name,
        row AS rowNum,
        column AS columnNum,
        owned AS owned,
        coins AS coins
      FROM villages;
      ''');

    print('printing maps');
    print(maps);

    return maps;
  }

  static Future<List<Village>> getEnemyVillages() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      *
    FROM villages
    WHERE owned = 0;
    ''');

    List<Village> villages = maps.map((map) => Village.fromMap(map)).toList();

    return villages;
  }

  static Future<List<Village>> getPlayerVillages() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      *
    FROM villages
    WHERE owned = 1;
    ''');

    List<Village> villages = maps.map((map) => Village.fromMap(map)).toList();

    return villages;
  }

  static Future<Map<int, Map<int, Map<String, dynamic>>>> fetchVillages() async {
    List<Map<String, dynamic>> tilesList = await getVillages();

    // Initializing an empty nested map structure.
    Map<int, Map<int, Map<String, dynamic>>> resultMap = {};

    // Iterate over each tile and populate the resultMap.
    for (var tile in tilesList) {
      int id = tile['id'];
      String name = tile['name'];
      int rowNum = tile['rowNum'];
      int columnNum = tile['columnNum'];
      int owned = tile['owned'];
      int coins = tile['coins'];

      if (!resultMap.containsKey(rowNum)) {
        resultMap[rowNum] = {};
      }

      resultMap[rowNum]![columnNum] = tile;
    }

    print('printing resultmap');
    print(resultMap);
    return resultMap;
  }

  static Future<Village?> getVillageByRowAndColumn(int row, int column) async {
    final db = await DatabaseHelper.instance.database;

    List<Map<String, dynamic>> results = await db.query(
      'villages',
      where: 'row = ? AND column = ?',
      whereArgs: [row, column],
    );

    // If no results were found, return null
    if (results.isEmpty) {
      return null;
    }

    // Assuming Tile has a factory method fromMap to create an instance from a Map
    return Village.fromMap(results.first);
  }

  // HABIT COMPLETION (main.dart)

  // Get the sum of all the townhalls to get the total reward factor
  static Future<double> getTotalRewardFactor() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
    SELECT SUM(b.level) as totalSum
    FROM buildings b
    INNER JOIN villages v ON b.village_id = v.id
    WHERE b.name = 'town_hall' AND v.owned = 1;
  ''');

    print(result);

    if(result[0]['totalSum'] == null){
      return 1.00;
    }

    int townHallSum = result[0]['totalSum'] as int;
    double totalRewardFactor = 1 + townHallSum * 0.2;
    return totalRewardFactor;

  }

  static Future<void> divideCoins(int difficulty) async {
    final db = await DatabaseHelper.instance.database;

    // Fetch town hall levels of all owned villages.
    final List<Map<String, dynamic>> townHallLevels = await db.rawQuery('''
    SELECT v.id, b.level as town_hall_level
    FROM buildings b
    INNER JOIN villages v ON b.village_id = v.id
    WHERE b.name = 'town_hall' AND v.owned = 1;
  ''');

    int totalTownHallSum = townHallLevels.fold(0, (sum, village) => sum + village['town_hall_level'] as int);
    double totalRewardFactor = 1 + totalTownHallSum * 0.2;
    double totalCoinsEarned = totalRewardFactor * difficulty;


    print(totalRewardFactor);
    print(totalTownHallSum);
    print(totalCoinsEarned);

    for (Map<String, dynamic> village in townHallLevels) {
      int villageId = village['id'];
      int townHallLevel = village['town_hall_level'];

      // Calculate coins for this village based on its proportion of the total town hall sum.
      int coinsForThisVillage = ((townHallLevel / totalTownHallSum) * totalCoinsEarned).round();

      print("----");
      print(villageId);
      print(coinsForThisVillage);
      // Update the coins of this village in the database.
      await db.rawUpdate(
          'UPDATE villages SET coins = coins + ? WHERE id = ?',
          [coinsForThisVillage, villageId]
      );
    }
  }



  // EVENTS
  static Future<Map> spawnVillage() async {
    final db = await DatabaseHelper.instance.database;

    //// get total number of villages to properly name the new one
    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM villages;
    ''');

    int numberOfVillages = 0;
    // The result list should contain a single map with a 'count' key
    if (result.isNotEmpty) {
      numberOfVillages = result.first['count'] as int;
    }

    //// get list of all combinations of row and column to make sure not a duplicate is entered in the database
    final List<Map<String, dynamic>> existingCombinations = await db.query(
      'villages',
      columns: ['row', 'column'],
    );

    // Convert the list of maps into a set for efficient searching
    final Set<Map<String, int>> existingSet = existingCombinations.map((map) {
      return {'row': map['row'] as int, 'column': map['column'] as int};
    }).toSet();

    int newRow, newColumn;
    final Random random = Random();

    do {
      // Generate a new 'row' and 'column', each in the range 0 to 30
      newRow = random.nextInt(31); // because nextInt is exclusive of its upper bound
      newColumn = random.nextInt(31);

      // Continue looping if this combination already exists in the database
    } while (existingSet.contains({'row': newRow, 'column': newColumn}));
    ////

    // insert to db
    await Village.insertVillage(db, Village(name: 'Enemy Village $numberOfVillages', owned: 0, row: newRow, column: newColumn, coins: 0));

    // Get the ID of the village that has just been inserted in order to call createInitialVillage() with the right ID
    final idResult = await db.rawQuery('SELECT LAST_INSERT_ROWID() as last_id;');

    int lastVillageId = idResult[0]['last_id'] as int;

    print('Spawned village with name Enemy Village $numberOfVillages has ID: $lastVillageId');


    await Village.createInitialVillage(db, lastVillageId);

    return {'row': newRow, 'column': newColumn};

  }

  Future<String> updateEnemyBuilding() async {

    var random = Random();
    var randomNumber = random.nextInt(2); // Generates a random integer from 1 to 3.
    print(randomNumber);
    List buildingTypes = ['town_hall', 'farm'];

    await upgradeBuildingLevel(buildingTypes[randomNumber]);

    return buildingTypes[randomNumber];
  }

  Future<Map> addEnemyUnit() async{

    List<Unit> unitList = await getUnits();

    // The odds of a unit to be added is inversely proportional to their cost.
    // So units with a high cost have a lower chance of being added.

    int totalCost = unitList.fold(0, (int currentTotal, Unit unit) {
      return currentTotal + unit.cost; // assuming cost is an integer field in the Unit class
    });

    print('total cost of all units for this village');
    print(totalCost);

    // Calculate weights for each unit (inversely proportional to cost)
    List<double> weights = unitList.map((unit) => totalCost / unit.cost).toList();

    // Calculate total weight
    double totalWeight = weights.reduce((a, b) => a + b);

    //// DIT MAG WEG NA TESTING
    // Calculate and print the probability for each unit
    for (var i = 0; i < unitList.length; i++) {
      double probability = weights[i] / totalWeight;
      print('The odds of ${unitList[i].name} being leveled up are ${probability * 100}%');
    }
    ////

    // Generate a random number
    var rng = Random();
    double rand = rng.nextDouble() * totalWeight; // Random value between 0 and totalWeight

    // Determine which unit to level up
    double cumulative = 0;
    for (var i = 0; i < unitList.length; i++) {
      cumulative += weights[i];
      if (rand <= cumulative) {
        unitList[i].addToAmount();
        return {'villageName':name, 'unit': unitList[i].name};
      }
    }

    return {};

  }

  Future<Map> trainEnemyUnit() async{
    List<Unit> unitList = await getUnits();

    // The odds of a unit to be added is inversely proportional to their cost.
    // So units with a high cost have a lower chance of being added.

    // A unit can only be trained if its level is below the max level of 10
    unitList.removeWhere((unit) => unit.level >= 10);

    if(unitList.isEmpty){
      return {'villageName':name, 'unit': 'all_units_max_level'};
    }

    int totalCost = unitList.fold(0, (int currentTotal, Unit unit) {
      return currentTotal + unit.cost; // assuming cost is an integer field in the Unit class
    });

    print('total cost of all units for this village');
    print(totalCost);

    // Calculate weights for each unit (inversely proportional to cost)
    List<double> weights = unitList.map((unit) => totalCost / unit.cost).toList();

    // Calculate total weight
    double totalWeight = weights.reduce((a, b) => a + b);

    //// DIT MAG WEG NA TESTING
    // Calculate and print the probability for each unit
    for (var i = 0; i < unitList.length; i++) {
      double probability = weights[i] / totalWeight;
      print('The odds of ${unitList[i].name} being leveled up are ${probability * 100}%');
    }
    ////

    // Generate a random number
    var rng = Random();
    double rand = rng.nextDouble() * totalWeight; // Random value between 0 and totalWeight

    // Determine which unit to level up
    double cumulative = 0;
    for (var i = 0; i < unitList.length; i++) {
      cumulative += weights[i];
      if (rand <= cumulative) {
        unitList[i].levelUp();
        return {'villageName':name, 'unit': unitList[i].name};
      }
    }

    return {};
  }


}
