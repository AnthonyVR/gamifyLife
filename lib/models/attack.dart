import 'dart:convert';
import 'dart:math';

import 'package:habit/models/unit.dart';
import 'package:habit/models/village.dart';
import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'settings.dart';


class Attack {
  final int? id;
  final int sourceVillageId;
  final int destinationVillageId;
  final DateTime startedAt;  // when the attack is started
  final DateTime arrivedAt;  // when the attack arrives
  late DateTime? returnedAt;
  final String sourceUnitsBefore;  // Serialized JSON representation of units and their amounts before the attack
  late String? destinationUnitsBefore;  // Serialized JSON representation of units and their amounts before the attack

  late String? sourceUnitsAfter;  // Serialized JSON representation of units and their amounts after the attack
  late String? destinationUnitsAfter;// Serialized JSON representation of units and their amounts after the attack
  late int? luck;
  late int? outcome; // 1 if player wins | 0 if cpu wins
  late int? loot; // Amount of loot gathered
  late String? damage;

  final int owned; // 1 if player initiated attack | 0 if cpu initiated attack

  int completed; // keeps track of whether the attack is already processed by the game. When the attack is finished, the updateUnitsInTransit() function from the village class
  // has to be called to place the returned units back in the village. If that function is called and the returned units are arrived but not yet returned back in the village, this flag will be set to 1.
  // If the units have returned to their village, the flag will be set to 2. Without this flag, the updateUnitsInTransit() would continuously be called even when the units have already arrived or returned.

  final String? sourceVillageName;
  final String? destinationVillageName;

  Attack({
    this.id,
    required this.sourceVillageId,
    required this.destinationVillageId,
    required this.startedAt,
    required this.arrivedAt,
    this.returnedAt,
    required this.sourceUnitsBefore,
    this.destinationUnitsBefore,
    this.sourceUnitsAfter,
    this.destinationUnitsAfter,
    this.luck,
    this.outcome,
    this.loot,
    this.damage,
    required this.owned,
    required this.completed,

    this.sourceVillageName,
    this.destinationVillageName
  });

  // Convert an Attack to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_village_id': sourceVillageId,
      'destination_village_id': destinationVillageId,
      'started_at': startedAt.toIso8601String(),
      'arrived_at': arrivedAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'source_units_before': sourceUnitsBefore,
      'destination_units_before': destinationUnitsBefore,
      'source_units_after': sourceUnitsAfter,
      'destination_units_after': destinationUnitsAfter,
      'luck': luck,
      'outcome': outcome,
      'loot': loot,
      'damage': damage,
      'owned': owned,
      'completed': completed,
    };
  }

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Convert a Map to an Attack
  static Attack fromMap(Map<String, dynamic> map) {
    return Attack(
      id: map['id'],
      sourceVillageId: map['source_village_id'],
      destinationVillageId: map['destination_village_id'],
      startedAt: DateTime.parse(map['started_at']),
      arrivedAt: DateTime.parse(map['arrived_at']),
      returnedAt: map['returned_at'] != null ? DateTime.parse(map['returned_at']) : null,
      sourceUnitsBefore: map['source_units_before'],
      destinationUnitsBefore: map['destination_units_before'],
      sourceUnitsAfter: map['source_units_after'],
      destinationUnitsAfter: map['destination_units_after'],
      luck: map['luck'],
      outcome: map['outcome'],
      loot: map['loot'],
      damage: map['damage'],
      owned: map['owned'],
      completed: map['completed'],

      sourceVillageName: map['source_village_name'],
      destinationVillageName: map['destination_village_name'],// This will be null if 'owned' isn't present in the map
    );
  }

  static Future<void> createTable(db) async {

    await db.execute('''
      CREATE TABLE attacks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source_village_id INTEGER,
          destination_village_id INTEGER,
          started_at TEXT NOT NULL,
          arrived_at TEXT NOT NULL,
          returned_at TEXT,
          source_units_before TEXT NOT NULL,
          destination_units_before TEXT,
          source_units_after TEXT,
          destination_units_after TEXT,
          luck INTEGER,
          outcome INTEGER,
          owned INTEGER,
          completed INTEGER,
          loot INTEGER,
          damage TEXT,
          FOREIGN KEY (source_village_id) REFERENCES villages(id),
          FOREIGN KEY (destination_village_id) REFERENCES villages(id)
      )
    ''');
  }

  Future<int> insertToDb() async {
    Database db = await _db;
    return await db.insert('attacks', toMap());
  }

  Future<int> updateToDb() async {
    Database db = await _db;

    return await db.update(
        'attacks', // table name
        toMap(),   // values
        where: 'id = ?', // update where id matches
        whereArgs: [id] // value for where argument (id of the Attack instance)
    );
  }



  //// LOGIC FOR ATTACK ITSELF

  // function runs when the attack is sent out by player or enemy
  static Future<void> createAttack(int sourceVillageId, int destinationVillageId, List<Map<String, dynamic>> sourceUnits) async{
    final db = await DatabaseHelper.instance.database;

    Village sourceVillage = await Village.getVillageById(sourceVillageId);
    Village destinationVillage = await Village.getVillageById(destinationVillageId);
    var currentTime = DateTime.now();

    print("PRINTING SOURCE UNITS FOR SLOWEST SPEED!");
    print(sourceUnits);

    int slowestSpeed = calculateSlowestSpeed(sourceUnits);

    print("test 1");

    double distanceBetweenVillages = calculateDistanceBetweenVillages(sourceVillage, destinationVillage);

    print("test 4");

    DateTime arrivalTime = _calculateArrivalTime(currentTime, distanceBetweenVillages, slowestSpeed);

    print("test 5");


    Attack attack = Attack(
      sourceVillageId: sourceVillageId,
      destinationVillageId: destinationVillageId,
      startedAt: currentTime,
      arrivedAt: arrivalTime,
      sourceUnitsBefore: serializeUnits(sourceUnits),
      owned: sourceVillage.owned,
      completed: 0,
    );

    attack.insertToDb();

    // remove attacking units from source village
    _removeUnitsFromAmounts(sourceUnits);

  }

  // runs when an attack is already sent out -> checks whether attack has already arrived and handles it
  static Future<void> handlePendingAttacks() async{
    final db = await DatabaseHelper.instance.database;

    List<Attack> attacks = await getIncompleteAttacks();

    // loop through all attacks
    for(Attack attack in attacks){

      print("-------------------------------------");
      print("attack id: ${attack.id}");

      // if the attack is arrived at destination but not yet returned home, handle the main attack logic
      if(attack.owned == 1 && attack.completed == 0 && DateTime.now().isAfter(attack.arrivedAt)){
        await attack.handleOutgoingAttack();
      } else if(attack.owned == 0 && attack.completed == 0 && DateTime.now().isAfter(attack.arrivedAt)){
        print("handling incoming attack ${attack.id}");
        await attack.handleIncomingAttack();
      }

      // if the attack has returned home, add the remaining units back in their village
      if (attack.completed == 1 && DateTime.now().isAfter(attack.returnedAt!)) {

        print('attack id: ${attack.id}');

        if (attack.sourceUnitsAfter != null) {
          print('sourceUnitsAfter: ${attack.sourceUnitsAfter}');

          List<Map<String, dynamic>> sourceUnitsAfter = (json.decode(attack.sourceUnitsAfter!) as List).cast<Map<String, dynamic>>();

          for (var unitData in sourceUnitsAfter) {
            int unitId = unitData['unit_id'];
            int amountToAdd = unitData['amount'];

            await db.rawUpdate('''
              UPDATE units
              SET amount = amount + ?
              WHERE id = ?
              ''', [amountToAdd, unitId]);
          }
          print("units from attack ${attack.id} added back to village");
        } else {
          print('sourceUnitsAfter is null for attack id: ${attack.id}');
        }

        // update the attack as "completed 2"
        await db.update('attacks', {'completed': 2}, where: 'id = ?', whereArgs: [attack.id]);

      }

    }
  }

  Future<void> handleOutgoingAttack() async{

    Village sourceVillage = await Village.getVillageById(sourceVillageId);
    Village destinationVillage = await Village.getVillageById(destinationVillageId);

    List destinationUnitsList = await destinationVillage.getUnits();


    List<Map<String, dynamic>> destinationUnitsDecoded = destinationUnitsList.map((unit) {
      return {
        'unit': unit,
        'amount': unit.amount,
      };
    }).toList();

    List<dynamic> sourceUnitsBeforeList = jsonDecode(sourceUnitsBefore);

    List<Map<String, dynamic>> sourceUnitsBeforeDecoded = [];
    for (var unitMap in sourceUnitsBeforeList) {
      int unitId = unitMap['unit_id'];
      var unit = await Unit.getUnitById(unitId);
      sourceUnitsBeforeDecoded.add({
        'unit': unit,
        'amount': unitMap['amount'],
      });
    }

    destinationUnitsBefore = serializeUnits(destinationUnitsDecoded);

    int totalOffence = _calculateStrength(sourceUnitsBeforeDecoded, 'offence');
    int totalDefence = _calculateStrength(destinationUnitsDecoded, 'defence');

    if(totalDefence.isNaN || totalDefence.isInfinite){
      totalDefence = 0;
    }

    int luckNumber = _generateLuck();
    double luckModifier = _calculateLuckModifier(luckNumber);

    luck = (luckModifier*100).round();

    print("total offense: ${totalOffence}");
    print("total defense: ${totalDefence}");

    totalOffence = (totalOffence * (1 + luckModifier)).round();
    totalDefence = (totalDefence * (1 - luckModifier)).round();

    int attackerCasualties;
    int defenderCasualties;

    // the decay model function makes gives less casualties for the winner when he has a
    // advantage and more losses when it's nearly equal
    // attackerCasualties=totalDefence×e−k(ratio−1)
    double ratio;
    if (totalDefence == 0) { // to prevent division by zero
      ratio = 10.0; // or some high number to indicate a huge imbalance in favor of the offense
    } else {
      ratio = totalOffence.toDouble() / totalDefence.toDouble();
    }

    const k = 1.0; // Adjust this constant based on game balancing needs

    if (totalOffence == totalDefence) {
      attackerCasualties = totalOffence;
      defenderCasualties = totalDefence;
    } else if (totalOffence > totalDefence) {
      // if player owns the source village and it wins, then outcome is 1
      if (owned == 1){
        outcome = 1;
      }
      defenderCasualties = totalDefence;
      attackerCasualties = (totalDefence * exp(-k * (ratio - 1))).round();
    } else {
      // if player owns the destination village and it wins, then outcome is 1
      if (owned == 0){
        outcome = 1;
      }
      attackerCasualties = totalOffence;
      defenderCasualties = (totalOffence * exp(-k * (1/ratio - 1))).round(); // This can remain as is or be adjusted similarly
    }

    List<Map<String, dynamic>> sourceUnitsAfterList = List.from(sourceUnitsBeforeDecoded);
    List<Map<String, dynamic>> destinationUnitsAfterList = List.from(destinationUnitsDecoded);

    _distributeCasualties(sourceUnitsAfterList, attackerCasualties, totalOffence);
    _distributeCasualties(destinationUnitsAfterList, defenderCasualties, totalDefence);

    print('1.sourceunitsbeforedecoded');
    print(sourceUnitsBeforeDecoded);
    print(sourceUnitsAfterList);
    print("-------------------");
    print(destinationUnitsBefore);
    print(destinationUnitsAfterList);

    sourceUnitsAfter = serializeUnits(sourceUnitsAfterList);
    destinationUnitsAfter = serializeUnits(destinationUnitsAfterList);

    int slowestReturnSpeed = calculateSlowestSpeed(sourceUnitsAfterList);
    double distanceBetweenVillages = calculateDistanceBetweenVillages(sourceVillage, destinationVillage);
    returnedAt = _calculateArrivalTime(arrivedAt, distanceBetweenVillages, slowestReturnSpeed);

    completed = 1;
    loot = 0;
    damage = "none";

    print("removing units from defending enemy vilage");
    print(destinationUnitsAfterList);

    // remove the casualties from the enemy village
    for (var unitData in destinationUnitsAfterList) {
      unitData['unit'].updateAmount(unitData['amount']);
    }



    // Functionality for damaging a village
    print("Running functionality for damaging a village...");
    int? destinationvillageTownhallLevel = await destinationVillage.getBuildingLevel("town_hall");

    int remainingCatapults = 0;
    for (var unitData in sourceUnitsAfterList) {
      if (unitData['unit'].name == 'catapult') {
        remainingCatapults += (unitData['amount'] as num).toInt();
      }
    }

    if (destinationvillageTownhallLevel != null) {
      int currentTownHallLevel = destinationvillageTownhallLevel;

      // Loop through each level check if we have enough catapults to decrease the level
      Settings? settings;
      settings = await Settings.getSettingsFromDB();
      final double costMultiplier = settings.costMultiplier;

      while (currentTownHallLevel > 0 && remainingCatapults >= pow(costMultiplier, currentTownHallLevel)) {
        print("another run!");
        print(remainingCatapults);
        print(pow(costMultiplier, currentTownHallLevel));
        remainingCatapults -= pow(costMultiplier, currentTownHallLevel).toInt(); // Subtract the catapults needed for this level
        currentTownHallLevel--; // Decrease town hall level by 1
      }

      // Set the new level only if it has changed
      if (currentTownHallLevel != destinationvillageTownhallLevel) {

        damage = "$destinationvillageTownhallLevel → $currentTownHallLevel";


        destinationvillageTownhallLevel = max(currentTownHallLevel, 0); // Ensure it doesn't go below 0
        await destinationVillage.updateBuildingLevel(
            "town_hall", destinationvillageTownhallLevel);
        print(
            "Town hall level decreased to $destinationvillageTownhallLevel due to catapults.");
      }
    }

      //await destinationVillage.updateBuildingLevel("town_hall", 10);


    // Functionality for conquering a village
    print(destinationvillageTownhallLevel);
    int numberOfOwnedVillages = await Village.getNumberOfOwnedVillages();
    print("player owns $numberOfOwnedVillages villages");
    print("King level is ${sourceUnitsAfterList.last['unit'].level}");

    if(sourceUnitsAfterList.last['unit'].name == 'king' && sourceUnitsAfterList.last['unit'].level >= numberOfOwnedVillages && sourceUnitsAfterList.last['amount'] > 0 && destinationvillageTownhallLevel == 0){

      print("Village will be conquered");
      destinationVillage.changeOwner(1);
    }

    updateToDb();

    print("------------- END OF FUNCTION ----------------");

  }

  Future<void> handleIncomingAttack() async {

    // late String? destinationUnitsBefore;  // Serialized JSON representation of units and their amounts before the attack

    Village sourceVillage = await Village.getVillageById(sourceVillageId);
    Village destinationVillage = await Village.getVillageById(destinationVillageId);

    List<Unit> destinationUnitsList = await destinationVillage.getDefendingUnits();

    // Create a map to keep track of unique row and unit combinations and their counts.
    Map<String, Map<String, dynamic>> uniqueRowUnits = {};

    for (Unit unit in destinationUnitsList) {
      // Create a unique key based on the row and unit type.
      String key = '${unit.row}-${unit.id}'; // Assuming 'id' uniquely identifies the unit type.

      // If this key is already in the map, increment the amount, otherwise add it to the map.
      if (uniqueRowUnits.containsKey(key)) {
        uniqueRowUnits[key]!['amount'] += 1; // Increment the count.
      } else {
        uniqueRowUnits[key] = {
          'unit': unit,
          'amount': 1,
          'row': unit.row,
        };
      }
    }

    List<dynamic> sourceUnitsBeforeList = jsonDecode(sourceUnitsBefore);

    List<Map<String, dynamic>> sourceUnitsBeforeDecoded = [];
    for (var unitMap in sourceUnitsBeforeList) {
      int unitId = unitMap['unit_id'];
      var unit = await Unit.getUnitById(unitId);
      sourceUnitsBeforeDecoded.add({
        'unit': unit,
        'amount': unitMap['amount'],
      });
    }


    // Convert the map back to a list.
    List<Map<String, dynamic>> destinationUnits = uniqueRowUnits.values.toList();

    print("destinationunits: ${destinationUnits}");

    destinationUnitsBefore = serializeUnits(destinationUnits);

    int totalOffence = _calculateStrength(sourceUnitsBeforeDecoded, 'offence');
    int totalDefence = _calculateStrength(destinationUnits, 'defence');

    print('totalOffence: $totalOffence | totalDefence: $totalDefence');

    if(totalDefence.isNaN || totalDefence.isInfinite){
      totalDefence = 0;
    }

    int luckNumber = _generateLuck();
    double luckModifier = _calculateLuckModifier(luckNumber);

    luck = (luckModifier*100).round();

    totalOffence = (totalOffence * (1 + luckModifier)).round();
    totalDefence = (totalDefence * (1 - luckModifier)).round();

    int attackerCasualties;
    int defenderCasualties;

    // the decay model function gives less casualties for the winner when he has an
    // advantage and more losses when it's nearly equal
    // attackerCasualties=totalDefence×e−k(ratio−1)
    double ratio;
    outcome = 0;
    if (totalDefence == 0) { // to prevent division by zero
      ratio = 10.0; // or some high number to indicate a huge imbalance in favor of the offense
    } else {
      ratio = totalOffence.toDouble() / totalDefence.toDouble();
    }

    const k = 1.0; // Adjust this constant based on game balancing needs

    if (totalOffence == totalDefence) {
      attackerCasualties = totalOffence;
      defenderCasualties = totalDefence;
    } else if (totalOffence > totalDefence) {
      // if player owns the source village and it wins, then outcome is 1
      if (owned == 1){
        outcome = 1;
      }
      defenderCasualties = totalDefence;
      attackerCasualties = (totalDefence * exp(-k * (ratio - 1))).round();
    } else {
      // if player owns the destination village and it wins, then outcome is 1
      if (owned == 0){
        outcome = 1;
      }
      attackerCasualties = totalOffence;
      defenderCasualties = (totalOffence * exp(-k * (1/ratio - 1))).round(); // This can remain as is or be adjusted similarly

    }

    List<Map<String, dynamic>> sourceUnitsAfterList = List.from(sourceUnitsBeforeDecoded);
    List<Map<String, dynamic>> destinationUnitsAfterList = List.from(destinationUnits);

    print("offender casualites: ${attackerCasualties}");
    print("defender casualties: ${defenderCasualties}");
    _distributeCasualties(sourceUnitsAfterList, attackerCasualties, totalOffence);
    _distributeDefendingPlayerCasualties(destinationUnitsAfterList, defenderCasualties, totalDefence);


    print("attack arrival time: $arrivedAt");
    print("luck: $luckModifier");


    print("source id: $sourceVillageId | destination id: $destinationVillageId");

    sourceUnitsAfter = serializeUnits(sourceUnitsAfterList);
    destinationUnitsAfter = serializeUnits(destinationUnitsAfterList);

    print("destinationUnits After: ${destinationUnitsAfter}");
    print("destinationUnits After with rows: ${destinationUnitsAfterList}");


    int slowestReturnSpeed = calculateSlowestSpeed(sourceUnitsAfterList);
    double distanceBetweenVillages = calculateDistanceBetweenVillages(sourceVillage, destinationVillage);
    returnedAt = _calculateArrivalTime(arrivedAt, distanceBetweenVillages, slowestReturnSpeed);

    completed = 1;
    loot = 0;
    damage = "none";

    await updateCasualtiesInTilesTable(destinationUnitsAfterList);


    // Functionality for damaging a village
    print("Running functionality for damaging a village...");
    int? destinationvillageTownhallLevel = await destinationVillage.getBuildingLevel("town_hall");

    int remainingCatapults = 0;
    for (var unitData in sourceUnitsAfterList) {
      if (unitData['unit'].name == 'catapult') {
        remainingCatapults += (unitData['amount'] as num).toInt();
      }
    }

    if (destinationvillageTownhallLevel != null) {
      int currentTownHallLevel = destinationvillageTownhallLevel;

      // Loop through each level check if we have enough catapults to decrease the level
      Settings? settings;
      settings = await Settings.getSettingsFromDB();
      final double costMultiplier = settings.costMultiplier;

      while (currentTownHallLevel > 0 && remainingCatapults >= pow(costMultiplier, currentTownHallLevel)) {
        print("another run!");
        print(remainingCatapults);
        print(pow(costMultiplier, currentTownHallLevel));
        remainingCatapults -= pow(costMultiplier, currentTownHallLevel).toInt(); // Subtract the catapults needed for this level
        currentTownHallLevel--; // Decrease town hall level by 1
      }

      // Set the new level only if it has changed
      if (currentTownHallLevel != destinationvillageTownhallLevel) {

        damage = "$destinationvillageTownhallLevel → $currentTownHallLevel";

        destinationvillageTownhallLevel = max(currentTownHallLevel, 0); // Ensure it doesn't go below 0
        await destinationVillage.updateBuildingLevel(
            "town_hall", destinationvillageTownhallLevel);
        print(
            "Town hall level decreased to $destinationvillageTownhallLevel due to catapults.");
      }

    }


    //await destinationVillage.updateBuildingLevel("town_hall", 10);


    // Functionality for conquering a village
    print(destinationvillageTownhallLevel);
    if(sourceUnitsAfterList.last['unit'].name == 'king' && sourceUnitsAfterList.last['amount'] > 0 && destinationvillageTownhallLevel == 0){
      print("Village will be conquered");
      destinationVillage.changeOwner(0);
      List villages = await Village.getEnemyVillages();
      destinationVillage.changeName("Not your village anymore ${villages.length}");
    }

    updateToDb();

  }

  ////


  //// helper functions
  static Future<List<Attack>> getIncompleteAttacks() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> attackMaps = await db.query(
        'attacks',
        where: 'completed != ?',
        whereArgs: [2]
    );

    // Convert the List<Map<String, dynamic> into a List<Attack>
    return List.generate(attackMaps.length, (i) {
      return Attack.fromMap(attackMaps[i]);
    });
  }

  static int calculateSlowestSpeed(List<Map<String, dynamic>> units) {

    print("test2");
    var filteredUnits = units.where((unitData) => unitData['amount'] > 0).toList();

    if (filteredUnits.isEmpty) {
      return 0;
    }

    print("test3");
    print(filteredUnits);
    return filteredUnits
        .map((unitData) => unitData['unit'].speed)
        .reduce((a, b) => a > b ? a : b);

  }

  static Future<double> calculateDistanceBetweenVillagesById(int sourceId, int destinationId) async {

    Village source = await Village.getVillageById(sourceId);
    Village destination = await Village.getVillageById(destinationId);

    return calculateDistanceBetweenVillages(source, destination);
  }

  static double calculateDistanceBetweenVillages(Village source, Village destination) {
    return sqrt(pow(destination.row - source.row, 2) + pow(destination.column - source.column, 2));
  }

  static DateTime _calculateArrivalTime(DateTime currentTime, double distance, int slowestSpeed) {
    final attackDuration = (distance * slowestSpeed).round();
    return currentTime.add(Duration(minutes: attackDuration));
  }

  static int _generateLuck() {
    Random random = Random();
    return random.nextInt(101);
  }

  static double _calculateLuckModifier(int luck) {
    return 0.3 * (luck - 50) / 100.0;
  }

  static int _calculateStrength(List<Map<String, dynamic>> units, String type) {
    return units.fold(0, (sum, unitMap) {
      Unit unit = unitMap['unit'];
      int amount = unitMap['amount'];
      if(type == 'offence'){
        return (sum + unit.offence * amount).round();

      } else if(type == 'defence'){
        return (sum + unit.defence * amount).round();
      } else {
        return 0;
      }
    });
  }

  static void _distributeCasualties(List<Map<String, dynamic>> units, int casualties, int totalStrength) {

    if (totalStrength == 0) {
      // If totalStrength is 0, all units take maximum casualties.
      for (Map<String, dynamic> unitMap in units) {
        unitMap['amount'] = 0; // All units are casualties.
      }
    } else {
      // Distribute casualties proportionally to unit strength.
      for (Map<String, dynamic> unitMap in units) {
        Unit unit = unitMap['unit'];
        int unitCasualties = (unitMap['amount'] * (casualties / totalStrength)).round();
        unitMap['amount'] = (unitMap['amount'] - unitCasualties).clamp(0, unitMap['amount']);
      }
    }
  }

  static void _distributeDefendingPlayerCasualties(List<Map<String, dynamic>> units, int casualties, int totalStrength) {
    units.sort((a, b) => b['unit'].row.compareTo(a['unit'].row));
    print('Sorted units by rows: $units');

    if (totalStrength == 0) {
      for (Map<String, dynamic> unitMap in units) {
        unitMap['amount'] = 0;
      }
      print('Total strength is 0. All units take maximum casualties.');
      return;
    }

    for (Map<String, dynamic> unitMap in units) {
      unitMap['initialAmount'] = unitMap['amount'];  // Set the initial amount for each unit first
    }

    int currentRow = units.first['unit'].row;
    List<Map<String, dynamic>> currentRowUnits = [];
    int currentRowStrength = 0;

    for (int i = 0; i < units.length; i++) {
      Map<String, dynamic> unitMap = units[i];
      Unit unit = unitMap['unit'];

      if (unit.row == currentRow) {
        currentRowUnits.add(unitMap);
        currentRowStrength += (unit.defence * unitMap['amount']).round();
        print('Added unit ${unit} to current row units. Current row strength is now $currentRowStrength.');
      }

      if (unit.row != currentRow || i == units.length - 1) {
        int casualtiesTaken = _distributeCasualtiesAmongUnits(currentRowUnits, casualties, currentRowStrength);

        print('casulties before subtracting: ${casualties}');
        print('casualties to be subtracted: ${casualtiesTaken}');

        casualties -= casualtiesTaken;

        print('Distributed casualties among current row units. Remaining casualties: $casualties');

        currentRowUnits = [];
        currentRowStrength = 0;
        if (unit.row != currentRow) {
          currentRow = unit.row;
          currentRowUnits = [unitMap];
          currentRowStrength = (unit.defence * unitMap['amount']).round();
          print('Starting new row: $currentRow. Current row strength is now $currentRowStrength.');
        }
      }
    }

    print('Final unit states: $units');
  }

  // Updated distribute casualties among units function
  static int _distributeCasualtiesAmongUnits(List<Map<String, dynamic>> units, int casualties, int totalStrength) {
    int casualtiesTaken = 0;

    print("_________________0________________");
    print('Initial casualties to distribute: $casualties');
    print('Total strength of current units: $totalStrength');

    for (var unitMap in units) {
      int unitStrength = (unitMap['unit'].defence * unitMap['amount']).round();
      double unitCasualtiesPercentage = unitStrength / totalStrength;
      int unitCasualties = (casualties * unitCasualtiesPercentage).round();

      print('----');
      print('Processing unit with strength: $unitStrength');
      print('Unit casualty percentage: $unitCasualtiesPercentage');
      print('Calculated casualties for this unit: $unitCasualties');

      if (unitCasualties > unitMap['amount'] * unitMap['unit'].defence) {
        casualtiesTaken += ((unitMap['amount'] as int) * (unitMap['unit'].defence)).round();
        print('Unit casualties greater than available amount. Taking all units as casualties.');
        unitMap['amount'] = 0;
      } else {
        casualtiesTaken += unitCasualties;
        unitMap['amount'] -= (unitCasualties / unitMap['unit'].defence).round();
        print('Updated amount after taking casualties: ${unitMap['amount']}');
      }
      print('Total casualties taken so far: $casualtiesTaken');
    }

    print('Final casualties taken from this group: $casualtiesTaken');
    return casualtiesTaken;
  }


  static void _removeUnitsFromAmounts(List<Map<String, dynamic>> units) {
    for (var unitData in units) {
      unitData['unit'].removeMultipleFromAmount(unitData['amount']);
    }
  }

  static List<Map<String, dynamic>> deepCopy(List<Map<String, dynamic>> original) {
      return original.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  static String serializeUnits(List<Map> units) {
    return jsonEncode(units.map((unitMap) => {
      'unit_id': unitMap['unit'].id,
      'amount': unitMap['amount']
    }).toList());
  }


  Future<void> updateCasualtiesInTilesTable(List<Map<String, dynamic>> units) async {
    Database db = await DatabaseHelper.instance.database;

    for (var unitMap in units) {
      print('Processing unit: ${unitMap['unit'].id}');

      // Determine the number of casualties
      int casualties = 0;
      if (unitMap.containsKey('initialAmount')) {
        casualties = unitMap['initialAmount'] - unitMap['amount'];
        print('Determined casualties for unit: $casualties');
      }

      if (casualties > 0) {
        print('Getting entries for deletion for unit ${unitMap['unit'].id} with row ${unitMap['row']}');
        // Query the 'tiles' table to get units for deletion
        final List<Map<String, dynamic>> entries = await db.query(
            'tiles',
            where: 'content_type = ? AND row_num = ? AND content_id = ?',
            whereArgs: ['unit', unitMap['row'], unitMap['unit'].id],
            orderBy: 'id ASC',  // assuming the ones to delete would be from the top
            limit: casualties  // limit to the number of casualties
        );

        print('Entries to delete: $entries');

        for (var entry in entries) {
          print('Deleting entry with id: ${entry['id']}');
          // Delete each entry
          await db.delete(
              'tiles',
              where: 'id = ?',
              whereArgs: [entry['id']]
          );
        }
      }
    }
  }

  static Future<List<Attack>> getAllAttacks() async {
    Database db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        attacks.*, 
        sourceVillage.name AS source_village_name, 
        destinationVillage.name AS destination_village_name 
      FROM attacks 
      LEFT JOIN villages AS sourceVillage ON attacks.source_village_id = sourceVillage.id 
      LEFT JOIN villages AS destinationVillage ON attacks.destination_village_id = destinationVillage.id 
      ORDER BY attacks.started_at DESC
    ''');
    return List.generate(maps.length, (i) => Attack.fromMap(maps[i]));
  }

}
