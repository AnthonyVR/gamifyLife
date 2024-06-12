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


  static Future<List<Event>> getAllEventsFromYesterday(DateTime currentDate) async {
    // Convert the current date to the start of the day
    DateTime startOfToday = DateTime(currentDate.year, currentDate.month, currentDate.day);
    // Calculate the start of yesterday
    DateTime startOfYesterday = startOfToday.subtract(Duration(days: 1));

    // Format the dates to match the format in the database (e.g., 'yyyy-MM-dd')
    String startOfYesterdayStr = "${startOfYesterday.toIso8601String().split('T')[0]}T00:00:00";
    String endOfYesterdayStr = "${startOfToday.toIso8601String().split('T')[0]}T00:00:00";

    print('startOfYesterdayStr');
    print(startOfYesterdayStr);
    print(endOfYesterdayStr);
    Database db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      *
    FROM events
    WHERE timestamp >= ? AND timestamp < ?
    ORDER BY id DESC 
  ''', [startOfYesterdayStr, endOfYesterdayStr]);

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

    info.clear();
    info['timeSinceOpened'] = timeSinceGameOpened;
    info['frequency'] = averageFrequency;

    info['eventOdds'] = lambda;

    info['randomValue'] = randomValue;
    // Calculate cumulative probability and determine the number of events
    int k = 0; // Starting at 0 events
    double cumulativeProbability = exp(-lambda);
    info['cumulativeProbability'] = cumulativeProbability;

    while (randomValue > cumulativeProbability) {

      k++;
      cumulativeProbability += pow(lambda, k) * exp(-lambda) / _factorial(k);
    }

    info['numberOfEvents'] = k;

    // print("time since game opened: $timeSinceGameOpened minutes");
    // print("average frequency: $averageFrequency");
    // print("odds of event occuring (lambda): $lambda");
    // print("random value: $randomValue");
    // print("cumulative probability: $cumulativeProbability");
    // print("numer of events: $k");

    // k is the number of events that occurred
    return k;
  }


  static void checkTownHallLevelsUps() async{

    // upgrade the town hall if it's the next day
    List<Event> yesterdayEvents = await getAllEventsFromYesterday(DateTime.now().subtract(Duration(hours: 8)));

    yesterdayEvents = yesterdayEvents.reversed.toList();
    print(yesterdayEvents);

    for(Event event in yesterdayEvents){
      print(event.eventType);
      if(event.eventType == 'townhall_upgrade'){
        Village.upgradeTownHallById(event.info);
      }
    }

  }

  // Helper function to calculate factorial
  int _factorial(int num) {
    if (num <= 1) return 1;
    return num * _factorial(num - 1);
  }


  Future<int> calculateEvents() async {

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

    Map allInfo = {};

    // backup of database
    if(lastGameOpened.day != currentTimeStamp.day) {
      try {
        await DatabaseHelper.instance.backupDatabase(currentTimeStamp);
        print("creating backup for ${currentTimeStamp.day}");

      } catch (e) {
        print(e);
      }
    }

    // calculate time between game opened
    int timeSinceGameOpened = currentTimeStamp.difference(lastGameOpened).inMinutes; // Change back to minutes
    allInfo['timeSinceOpened'] = timeSinceGameOpened;

    Random random = Random();

    int numberOfVillageSpawns =  calculateNumberOfEvents(timeSinceGameOpened, villageSpawnFrequency);
    //numberOfVillageSpawns = 0;

    for (int i = 0; i < numberOfVillageSpawns; i++) {

      Map coordinates = await Village.spawnVillage(db);

      int randomMinutes = random.nextInt(timeSinceGameOpened);
      DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes)); // Change back to minutes

      info['coordinates'] = coordinates;

      Event(timestamp: randomTimestamp, eventType: 'village_spawn', info: info).insertToDb();
      eventsOccurred++;
    }

    List<Village> villages = await Village.getEnemyVillages(db);

    for(Village village in villages){

      info['coordinates'] = "[${village.row}, ${village.column}]";

      int numberOfBuildingLevelUps =  calculateNumberOfEvents(timeSinceGameOpened, buildingLevelUpFrequency);
      allInfo['building_level_up_randomValue'] = info['randomValue'];
      allInfo['building_level_up_cumulativeProbability'] = info['cumulativeProbability'];
      allInfo['building_level_up_numberOfEvents'] = info['numberOfEvents'];

      //numberOfBuildingLevelUps = 0;
      for (int i = 0; i < numberOfBuildingLevelUps; i++) {

        String building = await village.updateEnemyBuilding();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes)); // Change back to minutes

        info['building'] = building;

        await Event(timestamp: randomTimestamp, eventType: 'building_level_up', info: info).insertToDb();
        eventsOccurred++;
      }


      int numberOfUnitCreations =  calculateNumberOfEvents(timeSinceGameOpened, unitCreationFrequency);
      print("time since game opened $timeSinceGameOpened");
      print("inital number of unit creations $numberOfUnitCreations");
      int? townhallLevel = await village.getBuildingLevel('town_hall');
      int? numberOfVillages = await Village.getNumberOfVillages();

      print("number of villages $numberOfVillages");
      Settings? settings;
      settings = await Settings.getSettingsFromDB(db);
      double costMultiplier = settings.costMultiplier;

      int spanwMultiplier = (1 * pow(costMultiplier, numberOfVillages - 1)).round().toInt();
      print(spanwMultiplier);

      print("spawn multiplier");

      print(spanwMultiplier); // Output will be an integer

      numberOfUnitCreations = numberOfUnitCreations * townhallLevel! * spanwMultiplier;

      print("townhall level ${village.name}: $townhallLevel");

      allInfo['unit_creation_randomValue'] = info['randomValue'];
      allInfo['unit_creation_cumulativeProbability'] = info['cumulativeProbability'];
      allInfo['unit_creation_numberOfEvents'] = info['numberOfEvents'];

      print("number of unit creations $numberOfUnitCreations");
      //numberOfUnitCreations = 0;
      for (int i = 0; i < numberOfUnitCreations; i++) {
        Map unitAdded = await village.addEnemyUnit();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes)); // Change back to minutes

        info['unitAdded'] = unitAdded;
        info['townHallLevel'] = townhallLevel;
        info['spawnMultiplier'] = spanwMultiplier;

        await Event(timestamp: randomTimestamp, eventType: 'unit_added', info: info).insertToDb();
        eventsOccurred++;
      }


      int numberOfUnitTrainings =  calculateNumberOfEvents(timeSinceGameOpened, unitTrainingFrequency);

      allInfo['unit_trained_randomValue'] = info['randomValue'];
      allInfo['unit_trained_cumulativeProbability'] = info['cumulativeProbability'];
      allInfo['unit_trained_numberOfEvents'] = info['numberOfEvents'];

      //numberOfUnitTrainings = 0;
      for (int i = 0; i < numberOfUnitTrainings; i++) {

        Map unitTrained = await village.trainEnemyUnit();

        int randomMinutes = random.nextInt(timeSinceGameOpened);
        DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes)); // Change back to minutes

        info['unitTrained'] = unitTrained;

        await Event(timestamp: randomTimestamp, eventType: 'unit_trained', info: info).insertToDb();
        eventsOccurred++;
      }


      int numberOfAttacks =  calculateNumberOfEvents(timeSinceGameOpened, attackFrequency);
      //each village can only attack the player once for each timeframe because the database logic does not allow otherwise
      numberOfAttacks = numberOfAttacks > 0 ? 1 : 0;
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
          DateTime randomTimestamp = lastGameOpened.add(Duration(minutes: randomMinutes)); // Change back to minutes

          await Attack.createAttack(randomTimestamp, village.id!, playerRandomVillageId, enemySourceUnits);
          Event(timestamp: randomTimestamp, eventType: 'attack', info: info).insertToDb();
          eventsOccurred++;

        }

      }

    }

    if(timeSinceGameOpened > 10) { // only insert gameOpened event if game hasn't been opened in 3 minutes to prevent event spamming
      await Event(timestamp: currentTimeStamp, eventType: 'game_opened', info: allInfo).insertToDb();
    }
    return eventsOccurred;

  }


}