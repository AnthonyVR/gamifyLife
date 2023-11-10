import 'dart:ffi';

import 'package:habit/models/attack.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/globals.dart';

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

    String appMode = GlobalVariables.appMode; // test | prod

    if(appMode == 'test') {
      print("App running in test mode");
      habitsTable = 'test_habits';
      daysTable = 'test_days';
      habitHistoryTable = 'test_habit_history';
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

    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate); //, onUpgrade: _onUpgrade
  }

  Future _onCreate(Database db, int version) async {

    await createInitialDatabase();

  }

  Future createInitialDatabase() async {

    final db = await database;

    await db.execute('''
          CREATE TABLE $habitsTable (
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

    await db.execute('''
          CREATE TABLE $daysTable (
            $columnDate TEXT PRIMARY KEY,
            $columnWeekday TEXT NOT NULL
          )
    ''');

    await db.execute('''
          CREATE TABLE $habitHistoryTable (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnDate DATE NOT NULL,
            $columnHabitID INTEGER NOT NULL,
            $columnCount INTEGER,
            FOREIGN KEY ($columnDate) REFERENCES days(date),
            FOREIGN KEY ($columnHabitID) REFERENCES habits(id)
          )
    ''');

    // CREATE TABLES
    await Player.createTable(db);
    await Settings.createTable(db);
    await Village.createTable(db);
    await Tile.createTable(db);
    await Building.createTable(db);
    await Unit.createTable(db);
    await MiscObject.createTable(db);
    await Attack.createTable(db);
    await Event.createTable(db);

    // CREATE INITIAL SETTINGS
    Settings settings = Settings(id: 1, villageSpawnFrequency: 60, buildingLevelUpFrequency: 20, unitCreationFrequency: 20, unitTrainingFrequency: 20, attackFrequency: 20, costMultiplier: 1.5);
    settings.insertToDb();

    // INSERT INITIAL PLAYER
    await Player.insertPlayer(db, Player(id: 1, level: 1, score: 0, rewardFactor: 1));

    // INSERT FIRST VILLAGES
    await Village.insertVillage(db, Village(id: 1, name: 'Your village', owned: 1, row: 15, column: 15, coins: 30));
    //await Village.insertVillage(db, Village(id: 2, name: 'Your village 2', owned: 1, row: 17, column: 17, coins: 40));
    await Village.insertVillage(db, Village(id: 3, name: 'Enemy village 1', owned: 0, row: 15, column: 16, coins: 100));
    //await Village.insertVillage(db, Village(id: 4, name: 'Enemy village 2', owned: 0, row: 18, column: 13, coins: 100));


    // CREATE INITIAL VILLAGE WITH ALL OF ITS INITIAL TILES, UNITS, AND BUILDINGS AND OBJECTS
    await Village.createInitialVillage(db, 1);
    //await Village.createInitialVillage(db, 2);
    await Village.createInitialVillage(db, 3);
    //await Village.createInitialVillage(db, 4);


    // FOR TESTING PURPOSE: add some units to own and enemy village
    // await Unit(villageId: 2, name: "spearman", image: "assets/spearman.png", level: 1, offence: 10, defence: 10, amount: 5, cost: 50, speed: 50).insertToDb();
    // await Unit(villageId: 2, name: "wizard", image: "assets/wizard.png", level: 1, offence: 20, defence: 5, amount: 3, cost: 80, speed: 80).insertToDb();
    //
    // await Unit(villageId: 1, name: "spearman", image: "assets/spearman.png", level: 1, offence: 10, defence: 10, amount: 8, cost: 50, speed: 50).insertToDb();
    // await Unit(villageId: 1, name: "wizard", image: "assets/wizard.png", level: 1, offence: 20, defence: 5, amount: 5, cost: 80, speed: 80).insertToDb();


  }



  Future<void> clearDatabase() async {
    final db = await database;
    print("Dropping all tables");
    // Get the list of tables
    List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    for (Map table in tables) {
      // Don't drop the system table
      if (table['name'] != 'android_metadata' && table['name'] != 'sqlite_sequence') {
        await db.execute('DROP TABLE ${table['name']}');
      }
    }
    print("All tables dropped");
  }


  Future<void> clearAndRebuildDatabase() async {

    await clearDatabase();
    await createInitialDatabase();

  }




// Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //
  //   print('Database version changed - Running _onUpgrade()...');
  //   if (oldVersion < 9) {
  //     await Village.createInitialVillage(100, 100, true);
  //   }
  // }

  // Future<void> placeElement(Database db, String content, String image, int row, int col, int overwritable) async {
  //   int tileId = row * 9 + col + 1;
  //
  //   var tile = {
  //     columnTileContent: content,
  //     columnTileImage: image,
  //     columnOverwritable: overwritable
  //   };
  //
  //   await db.update(
  //       tilesTable,
  //       tile,
  //       where: '$columnTileID = ?',
  //       whereArgs: [tileId]
  //   );
  // }


}
