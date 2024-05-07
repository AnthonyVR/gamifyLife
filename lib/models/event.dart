import 'dart:convert';
import 'dart:math';

import 'package:habit/models/settings.dart';
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

    final db = await DatabaseHelper.instance.database;
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

  Future<DateTime> getLastGameOpened(Database db) async{

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

    // print("time since game openen: $timeSinceGameOpened minutes");
    // print("average frequency: $averageFrequency");
    // print("odds of event occuring (lambda): $lambda");
    // print("random value: $randomValue");
    // print("cumulative probability: $cumulativeProbability");
    // print("numer of events: $k");

    // k is the number of events that occurred
    return k;
  }

  // Helper function to calculate factorial
  int _factorial(int num) {
    if (num <= 1) return 1;
    return num * _factorial(num - 1);
  }


  Future<int> calculateEvents() async {

    print("huuuuh");

    final db = await DatabaseHelper.instance.database;

    Settings settings = await Settings.getSettingsFromDB(db);

    int? villageSpawnFrequency = settings.villageSpawnFrequency; //3 * 24 * 60; // minutes
    int buildingLevelUpFrequency = settings.buildingLevelUpFrequency;
    int unitCreationFrequency = settings.unitCreationFrequency;
    int unitTrainingFrequency = settings.unitTrainingFrequency;
    int attackFrequency = settings.attackFrequency;

    int eventsOccurred = 0;

    DateTime lastGameOpened = await getLastGameOpened(db);
    DateTime currentTimeStamp = DateTime.now();

    // backup of database
    if(lastGameOpened.day != currentTimeStamp.day) {
      try {
        await DatabaseHelper.instance.backupDatabase(currentTimeStamp.day);
        print("creating backup for ${currentTimeStamp.day}");
      } catch (e) {
        print(e);
      }
    }

    // calculate time between game opened
    int timeSinceGameOpened = currentTimeStamp.difference(lastGameOpened).inMinutes;

    Random random = Random();

    int numberOfVillageSpawns =  calculateNumberOfEvents(timeSinceGameOpened, villageSpawnFrequency);
    //numberOfVillageSpawns = 0;
    for (int i = 0; i < numberOfVillageSpawns; i++) {

      Map coordinates = await Village.spawnVillage(db);

      int randomMinutes = random.nextInt(timeSinceGameOpened);
      DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes));

      Event(timestamp: randomTimestamp, eventType: 'village_spawn', info: coordinates).insertToDb();
      eventsOccurred++;
    }

    List<Village> villages = await Village.getEnemyVillages(db);

    for(Village village in villages){
      int? townhallLevel = await village.getBuildingLevel('town_hall');

      int numberOfBuildingLevelUps =  calculateNumberOfEvents(timeSinceGameOpened, buildingLevelUpFrequency);

      int numberOfUnitCreations =  calculateNumberOfEvents(timeSinceGameOpened, unitCreationFrequency);
      numberOfUnitCreations = numberOfUnitCreations * townhallLevel!;

      int numberOfUnitTrainings =  calculateNumberOfEvents(timeSinceGameOpened, unitTrainingFrequency);

      int numberOfAttacks =  calculateNumberOfEvents(timeSinceGameOpened, attackFrequency);

      //each village can only attack the player once for each timeframe because the database logic does not allow otherwise
      numberOfAttacks = numberOfAttacks > 0 ? 1 : 0;

      //numberOfBuildingLevelUps = 0;
      for (int i = 0; i < numberOfBuildingLevelUps; i++) {
        String building = await village.updateEnemyBuilding();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes));

        Event(timestamp: randomTimestamp, eventType: 'building_level_up', info: {'building' : building}).insertToDb();
        eventsOccurred++;
      }

      //numberOfUnitCreations = 0;
      for (int i = 0; i < numberOfUnitCreations; i++) {
        Map unitAdded = await village.addEnemyUnit();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes));

        Event(timestamp: randomTimestamp, eventType: 'unit_added', info: unitAdded).insertToDb();
        eventsOccurred++;
      }

      //numberOfUnitTrainings = 0;
      for (int i = 0; i < numberOfUnitTrainings; i++) {
        Map unitTrained = await village.trainEnemyUnit();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes));

        Event(timestamp: randomTimestamp, eventType: 'unit_trained', info: unitTrained).insertToDb();
        eventsOccurred++;
      }

      //numberOfAttacks = 0;
      for (int i = 0; i < numberOfAttacks; i++) {

        //// pick a random village from the player's villages (village that gets attacked)
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

        List<Unit> enemySourceUnitsList = await village.getAvailableUnits();

        if(enemySourceUnitsList.isNotEmpty){

          List<Map<String, dynamic>> enemySourceUnits = enemySourceUnitsList.map((unit) {
            return {
              'unit': unit,
              'amount': unit.amount,
            };
          }).toList();

          // REMOVE THIS LATER !!!
          //playerRandomVillageId = 1;

          int randomMinutes = random.nextInt(timeSinceGameOpened);
          DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes));

          await Attack.createAttack(randomTimestamp, village.id!, playerRandomVillageId, enemySourceUnits);
          Event(timestamp: randomTimestamp, eventType: 'attack', info: {}).insertToDb();
          eventsOccurred++;

        }

      }

    }

    return eventsOccurred;

  }


}
