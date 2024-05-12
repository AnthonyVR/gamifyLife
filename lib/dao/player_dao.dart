import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../models/player.dart';

class PlayerDao {

  final DatabaseHelper dbHelper;
  PlayerDao(this.dbHelper);

  Future<Player> getPlayer() async {
    Database db = await dbHelper.database;

    // Assuming that there's only one player and its ID is 1.
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.playerTable,
      where: 'id = ?',
      whereArgs: [1],
    );

    print("printing plaaeyyeyer");
    print(maps);

    if (maps.isNotEmpty) {
      return Player.fromMap(maps.first);
    } else {
      throw Exception('ID not found in database');
    }
  }

  Future<int> updatePlayer(Player player) async {
    Database db = await dbHelper.database;

    // Create a Map of column names and values.
    var row = {
      'id': player.id,
      'level': player.level,
      'score': player.score,
      'rewardFactor': player.rewardFactor,
      'total_coins_earned': player.totalCoinsEarned
    };

    return await db.update(
      DatabaseHelper.playerTable,
      row,
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }
}
