import 'dart:convert';
import 'dart:math';

import 'package:habit/models/unit.dart';
import 'package:habit/models/village.dart';
import 'package:habit/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class Attack {
  final int? id;
  final int sourceVillageId;
  final int destinationVillageId;
  final DateTime startedAt;  // when the attack is started
  final DateTime arrivedAt;  // when the attack arrives
  final String sourceUnitsBefore;  // Serialized JSON representation of units and their amounts before the attack
  final String destinationUnitsBefore;  // Serialized JSON representation of units and their amounts before the attack

  final String sourceUnitsAfter;  // Serialized JSON representation of units and their amounts after the attack
  final String destinationUnitsAfter;// Serialized JSON representation of units and their amounts after the attack
  final int luck;
  final int outcome; // 1 if player wins | 0 if cpu wins
  final int loot; // Amount of loot gathered
  final String damage;

  final int owned; // 1 if player initiated attack | 0 if cpu initiated attack
  final String? sourceVillageName;
  final String? destinationVillageName;

  Attack({
    this.id,
    required this.sourceVillageId,
    required this.destinationVillageId,
    required this.startedAt,
    required this.arrivedAt,
    required this.sourceUnitsBefore,
    required this.destinationUnitsBefore,
    required this.sourceUnitsAfter,
    required this.destinationUnitsAfter,
    required this.luck,
    required this.outcome,
    required this.loot,
    required this.damage,
    required this.owned,

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
      'source_units_before': sourceUnitsBefore,
      'destination_units_before': destinationUnitsBefore,
      'source_units_after': sourceUnitsAfter,
      'destination_units_after': destinationUnitsAfter,
      'luck': luck,
      'outcome': outcome,
      'loot': loot,
      'damage': damage,
      'owned': owned,
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
      sourceUnitsBefore: map['source_units_before'],
      destinationUnitsBefore: map['destination_units_before'],
      sourceUnitsAfter: map['source_units_after'],
      destinationUnitsAfter: map['destination_units_after'],
      luck: map['luck'],
      outcome: map['outcome'],
      loot: map['loot'],
      damage: map['damage'],
      owned: map['owned'],

      sourceVillageName: map['source_village_name'],
      destinationVillageName: map['destination_village_name'],// This will be null if 'owned' isn't present in the map
    );
  }

  static Future<void> createTable(db) async {

    print("recreating table!!!");

    await db.execute('''
      CREATE TABLE attacks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source_village_id INTEGER,
          destination_village_id INTEGER,
          started_at TEXT NOT NULL,
          arrived_at TEXT NOT NULL,
          source_units_before TEXT NOT NULL,
          destination_units_before TEXT NOT NULL,
          source_units_after TEXT,
          destination_units_after TEXT,
          luck INTEGER,
          outcome INTEGER,
          owned INTEGER,
          loot INTEGER,
          damage TEXT NOT NULL,
          FOREIGN KEY (source_village_id) REFERENCES villages(id),
          FOREIGN KEY (destination_village_id) REFERENCES villages(id)
      )
    ''');
  }

  Future<int> insertToDb() async {
    Database db = await _db;
    return await db.insert('attacks', toMap());
  }

  //// LOGIC FOR ATTACK ITSELF
    static int _calculateSlowestSpeed(List<Map<String, dynamic>> units) {
      return units.map((unitData) => unitData['unit'].speed).reduce((a, b) => a > b ? a : b);
    }

    static double _calculateDistanceBetweenVillages(Village source, Village destination) {
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
          return (sum + unit.offence * amount).round();
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
          int unitCasualties = (unitMap['amount'] * (casualties / totalStrength)).toInt();
          unitMap['amount'] = (unitMap['amount'] - unitCasualties).clamp(0, unit.amount);
        }
      }
    }


  static List<Map<String, dynamic>> deepCopy(List<Map<String, dynamic>> original) {
      return original.map((map) => Map<String, dynamic>.from(map)).toList();
    }

    static Future<void> attackVillage(int sourceVillageId, int destinationVillageId, List<Map<String, dynamic>> sourceUnits) async {
      final db = await DatabaseHelper.instance.database;

      Village sourceVillage = await Village.getVillageById(sourceVillageId);
      Village destinationVillage = await Village.getVillageById(destinationVillageId);
      var currentTime = DateTime.now();;

      int slowestSpeed = _calculateSlowestSpeed(sourceUnits);
      double distanceBetweenVillages = _calculateDistanceBetweenVillages(sourceVillage, destinationVillage);
      DateTime arrivalTime = _calculateArrivalTime(currentTime, distanceBetweenVillages, slowestSpeed);

      List destinationUnitsList = await destinationVillage.getUnits();
      List<Map<String, dynamic>> destinationUnits = destinationUnitsList.map((unit) {
        return {
          'unit': unit,
          'amount': unit.amount,
        };
      }).toList();

      List<Map<String, dynamic>> sourceUnitsBefore = deepCopy(sourceUnits);
      List<Map<String, dynamic>> destinationUnitsBefore = deepCopy(destinationUnits);


      int totalOffence = _calculateStrength(sourceUnits, 'offence');
      int totalDefence = _calculateStrength(destinationUnits, 'defence');

      if(totalDefence.isNaN || totalDefence.isInfinite){
        totalDefence = 0;
      }

      print("test");

      int luck = _generateLuck();
      double luckModifier = _calculateLuckModifier(luck);

      totalOffence = (totalOffence * (1 + luckModifier)).toInt();
      totalDefence = (totalDefence * (1 - luckModifier)).toInt();

      int attackerCasualties;
      int defenderCasualties;

      // the decay model function makes gives less casualties for the winner when he has a
      // advantage and more losses when it's nearly equal
      // attackerCasualties=totalDefence×e−k(ratio−1)
      double ratio;
      int outcome = 0;
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
        if (sourceVillage.owned == 1){
          outcome = 1;
        }
        defenderCasualties = totalDefence;
        attackerCasualties = (totalDefence * exp(-k * (ratio - 1))).toInt();
      } else {
        // if player owns the destination village and it wins, then outcome is 1
        if (destinationVillage.owned == 1){
          outcome = 1;
        }
        attackerCasualties = totalOffence;
        defenderCasualties = (totalOffence * exp(-k * (1/ratio - 1))).toInt(); // This can remain as is or be adjusted similarly
      }



      List<Map<String, dynamic>> sourceUnitsAfter = List.from(sourceUnits);
      List<Map<String, dynamic>> destinationUnitsAfter = List.from(destinationUnits);

      _distributeCasualties(sourceUnitsAfter, attackerCasualties, totalOffence);
      _distributeCasualties(destinationUnitsAfter, defenderCasualties, totalDefence);


      print(sourceUnitsBefore);
      print(destinationUnitsBefore);

      print(arrivalTime);
      print(luckModifier);


        print(sourceUnitsAfter);
        print(destinationUnitsAfter);


        print("source and destination id");
        print(sourceVillageId);
        print(destinationVillageId);

        String serializeUnits(List<Map> units) {
          return jsonEncode(units.map((unitMap) => {
            'unit': {
              'name': unitMap['unit'].name,
              'id': unitMap['unit'].id,
              'image': unitMap['unit'].image
            },
            'amount': unitMap['amount']
          }).toList());
        }

        Attack attack = Attack(
            sourceVillageId: sourceVillageId,
            destinationVillageId: destinationVillageId,
            startedAt: currentTime,
            arrivedAt: arrivalTime,
            sourceUnitsBefore: serializeUnits(sourceUnitsBefore),
            destinationUnitsBefore: serializeUnits(destinationUnitsBefore),
            sourceUnitsAfter: serializeUnits(sourceUnitsAfter),
            destinationUnitsAfter: serializeUnits(destinationUnitsAfter),
            luck: (luckModifier*100).round(),
            outcome: outcome,
            owned: sourceVillage.owned,
            loot: 0,
            damage: "None");

        attack.insertToDb();

    }

  ////


  //// FUNCTIONS FOR ATTACK_VIEW.DART

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
