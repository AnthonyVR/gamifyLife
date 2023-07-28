import 'package:flutter/cupertino.dart';
import '/services/database_helper.dart';

class Player {
  int id;
  int level;
  int score;
  int coins;

  Player({required this.id, required this.level, required this.score, required this.coins});

  Player.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        level = map['level'],
        score = map['score'],
        coins = map['coins'];


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'score': score,
      'coins': coins,
    };
  }
}

class PlayerModel extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  late Player _player;

  Player get player => _player;

  Future<void> loadPlayer() async {
    _player = await dbHelper.getPlayer();
    notifyListeners();
  }

  Future<void> addCoins(int coinsToAdd) async {
    _player.coins += coinsToAdd;
    await dbHelper.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> removeCoins(int coinsToRemove) async {
    _player.coins -= coinsToRemove;
    await dbHelper.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> addScore(int scoreToAdd) async {
    _player.score += scoreToAdd;
    await dbHelper.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> removeScore(int scoreToRemove) async {
    _player.score -= scoreToRemove;
    await dbHelper.updatePlayer(_player);
    notifyListeners();
  }

  Future<void> resetData() async {
    _player.score = 0;
    _player.level = 1;
    _player.coins = 0;

    await dbHelper.updatePlayer(_player);
    notifyListeners();
  }

}

