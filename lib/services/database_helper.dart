import 'dart:ffi';

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
import '../models/tile.dart';
import '../models/building.dart';
import '../models/unit.dart';
import '../models/misc_object.dart';
import '../models/village.dart';


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

  static final columnId = '_id';
  static final columnTitle = 'title';
  static final columnReward = 'reward';
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
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $habitsTable (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnReward INTEGER NOT NULL,
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


    await db.execute('''
          CREATE TABLE player (
            $columnPlayerId INTEGER PRIMARY KEY,
            $columnLevel INTEGER,
            $columnScore INTEGER,
            $columnCoins INTEGER
          )
    ''');


    // await db.execute('''
    //       CREATE TABLE $villagesTable (
    //         $columnId INTEGER PRIMARY KEY,
    //         $columnName TEXT,
    //         $columnTownCenter INTEGER,
    //         $columnBarracks INTEGER,
    //         $columnFarm INTEGER
    //       )
    //    ''');
    await db.insert(
      villagesTable,
      {
        columnName: 'My Village',
        columnTownCenter: 1,
        columnBarracks: 1,
        columnFarm: 1,
      },
    );

    // CREATE TABLES
    await Village.createTable(db);
    await Tile.createTable(db);
    await Building.createTable(db);
    await Unit.createTable(db);
    await MiscObject.createTable(db);

    // CREATE INITIAL VILLAGE WITH ALL OF ITS INITIAL TILES, UNITS, AND BUILDINGS AND OBJECTS
    await Village.createInitialVillage(100, 100, true);

  }


  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {

    print('Database version changed - Running _onUpgrade()...');
    if (oldVersion < 9) {
      await Village.createInitialVillage(100, 100, true);
    }
  }

  Future<void> placeElement(Database db, String content, String image, int row, int col, int overwritable) async {
    int tileId = row * 9 + col + 1;

    var tile = {
      columnTileContent: content,
      columnTileImage: image,
      columnOverwritable: overwritable
    };

    await db.update(
        tilesTable,
        tile,
        where: '$columnTileID = ?',
        whereArgs: [tileId]
    );
  }


}
