import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import '/services/database_helper.dart';

class Player {
  int id;
  int level;
  int score;
  int rewardFactor;
  int totalCoinsEarned;

  Player({required this.id, required this.level, required this.score, required this.rewardFactor, required this.totalCoinsEarned});

  Player.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        level = map['level'],
        score = map['score'],
        rewardFactor = map['rewardFactor'],
        totalCoinsEarned = map['total_coins_earned'];


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'score': score,
      'rewardFactor': rewardFactor,
      'total_coins_earned': totalCoinsEarned
    };
  }

  static Future<void> createTable(db) async {

    await db.execute('''
      CREATE TABLE player (
        id INTEGER PRIMARY KEY,
        level INTEGER NOT NULL,
        score INTEGER NOT NULL,
        rewardFactor INTEGER NOT NULL,
        total_coins_earned INTEGER NOT NULL
        )
    ''');
  }

  static Future<int> insertPlayer(db, Player player) async {

    return await db.insert('player', player.toMap());
  }

  static Future<Player> getPlayer() async {
    final dbHelper = DatabaseHelper.instance;

    return await dbHelper.playerDao.getPlayer();
  }

}

class PlayerModel extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  Player _player = Player(id: 1, level: 1, score: 0, rewardFactor: 0, totalCoinsEarned: 0);

  Player get player => _player;

  Future<void> loadPlayer() async {
    _player = await dbHelper.playerDao.getPlayer();
    notifyListeners();
  }

  Future<void> addRewardFactor(int rewardFactorToAdd) async {
    _player.rewardFactor += rewardFactorToAdd;
    await dbHelper.playerDao.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> removeRewardFactor(int rewardFactorToRemove) async {
    _player.rewardFactor -= rewardFactorToRemove;
    await dbHelper.playerDao.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> addScore(int scoreToAdd) async {
    _player.score += scoreToAdd;
    await dbHelper.playerDao.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> removeScore(int scoreToRemove) async {
    _player.score -= scoreToRemove;
    await dbHelper.playerDao.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> resetData() async {
    _player.score = 0;
    _player.level = 1;
    _player.rewardFactor = 1;

    await dbHelper.playerDao.updatePlayer(_player);
    notifyListeners();
  }

}

