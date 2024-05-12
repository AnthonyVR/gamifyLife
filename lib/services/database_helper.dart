import 'dart:ffi';

import 'package:habit/models/attack.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/globals.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Import the DAOs
import '../dao/habit_dao.dart';
import '../dao/day_dao.dart';
import '../dao/habit_history_dao.dart';
import '../dao/player_dao.dart';
import '../dao/village_dao.dart';

// Import classes
import '../models/player.dart';
import '../models/settings.dart';
import '../models/tile.dart';
import '../models/building.dart';
import '../models/unit.dart';
import '../models/misc_object.dart';
import '../models/village.dart';
import '../models/event.dart';




class DatabaseHelper {

  // Make this a singleton class
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();

  static DatabaseHelper get instance => _instance;

  DatabaseHelper._privateConstructor();

  static const _databaseName = "HabitDatabase.db";
  static const _databaseVersion = 9;

  // Create an instance of each DAO
  HabitDao? _habitDao;
  HabitDao get habitDao => _habitDao ??= HabitDao(this);

  DayDao? _dayDao;
  DayDao get dayDao => _dayDao ??= DayDao(this);

  HabitHistoryDao? _habitHistoryDao;
  HabitHistoryDao get habitHistoryDao => _habitHistoryDao ??= HabitHistoryDao(this);

  PlayerDao? _playerDao;
  PlayerDao get playerDao => _playerDao ??= PlayerDao(this);

  VillageDao? _villageDao;
  VillageDao get villageDao => _villageDao ??= VillageDao(this);

  // ++++++++++++ TABLES AND COLUMNS +++++++++++++++ //

  // HABITS TABLE
  static String habitsTable = 'habits';

  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnDifficulty = 'difficulty';
  static const columnMonday = 'monday';
  static const columnTuesday = 'tuesday';
  static const columnWednesday = "wednesday";
  static const columnThursday = "thursday";
  static const columnFriday = "friday";
  static const columnSaturday = "saturday";
  static const columnSunday = "sunday";
  static const columnCreated = "created";
  //


  // DAYS TABLE
  static String daysTable = 'days';

  static const columnWeekday = 'weekday';

  //

  // HABIT HISTORY TABLE
  static String habitHistoryTable = 'habit_history';

  static const columnHistoryID = 'id';
  static const columnHabitID = 'habit_id';
  static const columnDate = 'date';
  static const columnCount = 'count';
  //

  // PLAYER TABLE
  static String playerTable = 'player';

  static const columnPlayerId = 'id';
  static const columnLevel = 'level';
  static const columnScore = 'score';
  static const columnCoins = 'coins';


  // VILLAGES TABLE
  static String villagesTable = 'villages';

  static const columnName = 'name';
  static const columnTownCenter = 'townCenter';
  static const columnBarracks = 'barracks';
  static const columnFarm = 'farm';

  // VILLAGETILES TABLE
  final String tilesTable = 'village_tiles';

  final String columnTileID = 'tile_id'; // Primary Key
  final String columnTileRow = 'tile_row';
  final String columnTileColumn = 'tile_column';
  final String columnTileContent = 'tile_content';
  final String columnTileImage = 'tile_image';
  final String columnOverwritable = 'overwritable';

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    print("debugging test 2");
    return _database!;
  }

  // Open the database
  initDatabase() async {

    if (_database != null) {
      await _database!.close();  // Close the existing database connection
      _database = null;          // Set the _database to null to ensure reinitialization
    }

    String appMode = GlobalVariables.appMode; // test | prod

    String path = join(await getDatabasesPath(), "${appMode}_$_databaseName");

    if(appMode == 'test') {
      print("App running in test mode");
      habitsTable = 'habits';
      daysTable = 'days';
      habitHistoryTable = 'habit_history';
    }
    else if (appMode == 'prod') {
      print("App running in production mode!");
      habitsTable = 'habits';
      daysTable = 'days';
      habitHistoryTable = 'habit_history';
    }
    else {
      print("invalid app mode");
    }

    _database = await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
    return _database!;
  }

  Future _onCreate(Database db, int version) async {

    print("running _onCreate()");

    await createInitialDatabase(db);

  }

  Future<void> backupDatabase(DateTime timestamp) async {
    // Format the timestamp
    String formattedTimestamp = DateFormat('yyyy-MM-dd_HH:mm:ss').format(timestamp);

    // Paths
    String dbPath = join(await getDatabasesPath(), "${GlobalVariables.appMode}_$_databaseName");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String backupPath = join(documentsDirectory.path, "${GlobalVariables.appMode}_${_databaseName}_$formattedTimestamp.backup");

    // Copy the file
    File originalFile = File(dbPath);
    await originalFile.copy(backupPath);

    print("Backup created at $backupPath");
  }

  Future<String> getBackupPath(String formattedTimestamp) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, "${GlobalVariables.appMode}_${_databaseName}_$formattedTimestamp.backup");
  }

  Future<String> restoreDatabaseFromBackup(String backupFileName) async {
    String status = "Failed to restore";
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String backupPath = join(documentsDirectory.path, backupFileName);

      File backupFile = File(backupPath);
      if (await backupFile.exists()) {
        String dbPath = join(await getDatabasesPath(), "${GlobalVariables.appMode}_$_databaseName");
        await backupFile.copy(dbPath);
        status = "Restore successful!";
        print("Database restored from backup at $backupPath");
      } else {
        status = "Backup file does not exist.";
        print("Backup file $backupPath does not exist.");
      }
    } catch (e) {
      print("Failed to restore the database: $e");
    }
    return status;
  }

  Future createInitialDatabase(Database db) async {

    print("Running function createInitialDatabase()...");

    await db.execute('''
          CREATE TABLE IF NOT EXISTS $habitsTable (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnDifficulty INTEGER NOT NULL,
            $columnMonday INTEGER NOT NULL,
            $columnTuesday INTEGER NOT NULL,
            $columnWednesday INTEGER NOT NULL,
            $columnThursday INTEGER NOT NULL,
            $columnFriday INTEGER NOT NULL,
            $columnSaturday INTEGER NOT NULL,
            $columnSunday INTEGER NOT NULL,
            $columnCreated TEXT NOT NULL
                      )
          ''');


    print("Table habitsTable created");

    await db.execute('''
          CREATE TABLE IF NOT EXISTS $daysTable (
            $columnDate TEXT PRIMARY KEY,
            $columnWeekday TEXT NOT NULL
          )
    ''');

    print("Table daysTable created");

    
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $habitHistoryTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnDate DATE NOT NULL,
            $columnHabitID INTEGER NOT NULL,
            $columnCount INTEGER,
            FOREIGN KEY ($columnDate) REFERENCES days(date),
            FOREIGN KEY ($columnHabitID) REFERENCES habits(id)
          )
    ''');

    print("Table habitHistoryTable created");


    // CREATE TABLES
    await Player.createTable(db);
    print("Table Player created");

    await Settings.createTable(db);
    print("Table Settings created");

    await Village.createTable(db);
    print("Table Village created");

    await Tile.createTable(db);
    print("Table Tile created");

    await Building.createTable(db);
    print("Table Building created");

    await Unit.createTable(db);
    print("Table Unit created");

    await MiscObject.createTable(db);
    print("Table MiscObject created");

    await Attack.createTable(db);
    print("Table Attack created");

    await Event.createTable(db);
    print("Table Event created");


    // CREATE INITIAL SETTINGS
    int divider = 24; //set this number to easily change speed of the game for testing (e.g. for value 24, the game can be played hourly instead of daily)
    Settings settings = Settings(id: 1, villageSpawnFrequency: ((3*24*60) / divider).round(), buildingLevelUpFrequency: ((1*24*60) / divider).round(), unitCreationFrequency: ((0.5*24*60) / divider).round(), unitTrainingFrequency: ((3*24*60) / divider).round(), attackFrequency: ((3*24*60) / divider).round(), costMultiplier: 1.3);
    settings.insertToDb(db);

    //Settings ssettings = await Settings.getSettingsFromDB(db);

    // INSERT INITIAL PLAYER
    await Player.insertPlayer(db, Player(id: 1, level: 1, score: 0, rewardFactor: 1, totalCoinsEarned: 0));

    // INSERT FIRST VILLAGES
    await Village.insertVillage(db, Village(id: 1, name: 'Your village', owned: 1, row: 15, column: 15, coins: 0, totalCoinsEarned: 0));
    await Village.insertVillage(db, Village(id: 2, name: 'Enemy village 1', owned: 0, row: 12, column: 18, coins: 0, totalCoinsEarned: 0));
    //await Village.insertVillage(db, Village(id: 3, name: 'Your village 2', owned: 1, row: 14, column: 15, coins: 0));
    //await Village.insertVillage(db, Village(id: 4, name: 'Enemy village 2', owned: 0, row: 14, column: 16, coins: 100));
    //await Village.insertVillage(db, Village(id: 5, name: 'Enemy village 3', owned: 0, row: 16, column: 15, coins: 100));


    // CREATE INITIAL VILLAGE WITH ALL OF ITS INITIAL TILES, UNITS, AND BUILDINGS AND OBJECTS
    await Village.createInitialVillage(db, 1);
    await Village.createInitialVillage(db, 2);
    //await Village.createInitialVillage(db, 3);
    // await Village.createInitialVillage(db, 4);
    // await Village.createInitialVillage(db, 5);



    // FOR TESTING PURPOSE: add some units to own and enemy village
    // await Unit(villageId: 2, name: "spearman", image: "assets/spearman.png", level: 1, offence: 10, defence: 10, amount: 5, cost: 50, speed: 50).insertToDb();
    // await Unit(villageId: 2, name: "wizard", image: "assets/wizard.png", level: 1, offence: 20, defence: 5, amount: 3, cost: 80, speed: 80).insertToDb();
    //
    // await Unit(villageId: 1, name: "spearman", image: "assets/spearman.png", level: 1, offence: 10, defence: 10, amount: 8, cost: 50, speed: 50).insertToDb();
    // await Unit(villageId: 1, name: "wizard", image: "assets/wizard.png", level: 1, offence: 20, defence: 5, amount: 5, cost: 80, speed: 80).insertToDb();

    print("Function createInitialDatabase() finished");
  }



  Future<void> clearDatabase() async {
    final db = await database;
    print("Running function clearDatabase()...");
    // Get the list of tables
    List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (Map table in tables) {
      // Don't drop the system table
      if (table['name'] != 'android_metadata' && table['name'] != 'sqlite_sequence') {
        await db.execute('DROP TABLE ${table['name']}');
      }
    }
    print("function clearDatabase() finished");
  }

  Future<void> clearDatabaseExceptHabits() async {
    final db = await database;
    print("Running function clearDatabase()...");
    // Get the list of tables
    List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (Map table in tables) {
      // Don't drop the system table
      if (table['name'] != 'android_metadata' && table['name'] != 'sqlite_sequence' && table['name'] != 'habits' && table['name'] != 'days'  && table['name'] != 'habit_history'  && table['name'] != 'settings') {
        await db.execute('DROP TABLE ${table['name']}');
      }
    }
    print("function clearDatabase() finished");
  }


  Future<void> clearAndRebuildDatabase() async {

    print("REMOVING AND REBUILDING DATABASE");

    final db = await database;

    await clearDatabase();
    await createInitialDatabase(db);

  }

  Future<void> clearAndRebuildDatabaseExceptHabits() async {

    print("REMOVING AND REBUILDING DATABASE EXCEPT HABITS");

    final db = await database;

    await clearDatabaseExceptHabits();
    await createInitialDatabase(db);

  }



}
