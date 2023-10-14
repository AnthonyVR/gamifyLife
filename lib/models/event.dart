import 'dart:convert';
import 'dart:math';

import 'package:habit/models/unit.dart';
import 'package:habit/models/village.dart';
import 'package:sqflite/sqflite.dart';
import 'package:habit/services/database_helper.dart';

import 'attack.dart';

class Event {
  final int? id;
  final DateTime timestamp;
  final String eventType;// Type of event, e.g., "game_opened", "village_spawned", etc.
  final Map info;


  Event({
    this.id,
    required this.timestamp,
    required this.eventType,
    required this.info
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(), // Store the DateTime as a string in your DB
      'event_type': eventType,
      'info': jsonEncode(info), // Convert the Map to a JSON string for storage
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      eventType: map['event_type'],
      info: jsonDecode(map['info']), // Decode the JSON string back to a Map
    );
  }

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        event_type TEXT NOT NULL,
        info TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertToDb() async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('events', toMap());
  }

  static Future<List<Event>> getAllEvents() async {
    Database db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        *
      FROM events
      ORDER BY id DESC 
    ''');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<DateTime> getLastGameOpened() async{
    Database db = await DatabaseHelper.instance.database;

    // The query returns the latest 'game_opened' event ordered by timestamp in descending order
    List<Map<String, dynamic>> result = await db.query(
      'events',
      where: "event_type = ?",
      whereArgs: ['game_opened'],
      orderBy: "timestamp DESC",
      limit: 1,
    );

    if (result.isNotEmpty) {
      // If there's a result, return the timestamp as DateTime
      return DateTime.parse(result.first['timestamp']);
    } else {
      return DateTime.now();
    }

  }

  int calculateNumberOfEvents(int timeSinceGameOpened, int averageFrequency) {
    // Define constants
    final lambda = timeSinceGameOpened / averageFrequency; // Events per time frame

    // Create a random number generator
    final random = Random();

    // Generate a random number between 0 and 1
    final double randomValue = random.nextDouble();

    // Calculate cumulative probability and determine the number of events
    int k = 0; // Starting at 0 events
    double cumulativeProbability = exp(-lambda);

    while (randomValue > cumulativeProbability) {
      k++;
      cumulativeProbability += pow(lambda, k) * exp(-lambda) / _factorial(k);
    }

    // k is the number of events that occurred
    return k;
  }

  // Helper function to calculate factorial
  int _factorial(int num) {
    if (num <= 1) return 1;
    return num * _factorial(num - 1);
  }


  Future<int> calculateEvents() async {

    int villageSpawnFrequency = 20; // hours
    int buildingLevelUpFrequency = 20;
    int unitCreationFrequency = 20;
    int unitTrainingFrequency = 20;
    int attackFrequency = 20;

    int eventsOccurred = 0;


    Database db = await DatabaseHelper.instance.database;

    DateTime lastGameOpened = await getLastGameOpened();
    print(lastGameOpened);

    DateTime currentTimeStamp = DateTime.now();

    // calculate time between game opened
    int hoursSinceGameOpened = currentTimeStamp.difference(lastGameOpened).inMinutes;
    print(hoursSinceGameOpened);


    int numberOfVillageSpawns =  calculateNumberOfEvents(hoursSinceGameOpened, villageSpawnFrequency);
    //numberOfVillageSpawns = 0;
    for (int i = 0; i < numberOfVillageSpawns; i++) {
      Map coordinates = await Village.spawnVillage();
      Event(timestamp: currentTimeStamp, eventType: 'village_spawn', info: coordinates).insertToDb();
      eventsOccurred++;
    }

    List<Village> villages = await Village.getEnemyVillages();

    for(Village village in villages){
      int numberOfBuildingLevelUps =  calculateNumberOfEvents(hoursSinceGameOpened, buildingLevelUpFrequency);
      int numberOfUnitCreations =  calculateNumberOfEvents(hoursSinceGameOpened, unitCreationFrequency);
      int numberOfUnitTrainings =  calculateNumberOfEvents(hoursSinceGameOpened, unitTrainingFrequency);
      int numberOfAttacks =  calculateNumberOfEvents(hoursSinceGameOpened, attackFrequency);

      //numberOfBuildingLevelUps = 0;
      for (int i = 0; i < numberOfBuildingLevelUps; i++) {
        String building = await village.updateEnemyBuilding();
        print(building);
        Event(timestamp: currentTimeStamp, eventType: 'building_level_up', info: {'building' : building}).insertToDb();
        eventsOccurred++;
      }

      //numberOfUnitCreations = 0;
      for (int i = 0; i < numberOfUnitCreations; i++) {
        Map unitAdded = await village.addEnemyUnit();
        print(unitAdded);
        Event(timestamp: currentTimeStamp, eventType: 'unit_added', info: unitAdded).insertToDb();
        eventsOccurred++;
      }

      //numberOfUnitTrainings = 0;
      for (int i = 0; i < numberOfUnitTrainings; i++) {
        Map unitTrained = await village.trainEnemyUnit();
        print(unitTrained);
        Event(timestamp: currentTimeStamp, eventType: 'unit_trained', info: unitTrained).insertToDb();
        eventsOccurred++;
      }

      //numberOfAttacks = 0;
      for (int i = 0; i < numberOfAttacks; i++) {

        //// pick a random village from the player's villages
        List<Village> playerVillages = await Village.getPlayerVillages();

        // Create a Random instance
        var random = Random();

        // Generate a random index based on the list length
        int randomIndex = random.nextInt(playerVillages.length);

        // Get the village at the random index
        Village randomVillage = playerVillages[randomIndex];

        // Access the 'id' of the randomly selected village
        int playerRandomVillageId = randomVillage.id!;

        ////

        List<Unit> enemySourceUnitsList = await village.getUnits();

        List<Map<String, dynamic>> enemySourceUnits = enemySourceUnitsList.map((unit) {
          return {
            'unit': unit,
            'amount': unit.amount,
          };
        }).toList();

        // REMOVE THIS LATER !!!
        playerRandomVillageId = 1;

        Map attackInfo = await Attack.attackPlayerVillage(village.id!, playerRandomVillageId, DateTime.now(), enemySourceUnits);
        Event(timestamp: currentTimeStamp, eventType: 'attack', info: {}).insertToDb();
        eventsOccurred++;
      }


    }

    return eventsOccurred;

  }


}
