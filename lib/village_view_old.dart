import 'dart:math';

import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';


class VillageView extends StatefulWidget {
  const VillageView({Key? key}) : super(key: key);

  @override
  _VillageViewState createState() => _VillageViewState();
}

class _VillageViewState extends State<VillageView> {
  // Define images for each tile type
  final String grassImage = 'assets/village_package/tiles/medievalTile_57.png';
  final String buildingImage = 'assets/village_package/tiles/medievalTile_47.png';
  final String pathVertical = 'assets/village_package/tiles/medievalTile_03.png';
  final String pathHorizontal = 'assets/village_package/tiles/medievalTile_04.png';
  final String pathCrossed = 'assets/village_package/tiles/medievalTile_05.png';
  final String pathTopLeftCorner = 'assets/village_package/tiles/medievalTile_17.png';
  final String pathTopRightCorner = 'assets/village_package/tiles/medievalTile_18.png';
  final String pathBottomLeftCorner = 'assets/village_package/tiles/medievalTile_31.png';
  final String pathBottomRightCorner = 'assets/village_package/tiles/medievalTile_32.png';
  final String pathEndVertical = 'assets/village_package/tiles/medievalTile_34.png';


  final String wallHorizontal = 'assets/village_package/structure/wall_horizontal.png';
  final String wallVertical = 'assets/village_package/structure/wall_vertical.png';
  final String wallCornerTopLeft = 'assets/village_package/structure/wall_corner_top_left.png';
  final String wallCornerTopRight = 'assets/village_package/structure/wall_corner_top_right.png';
  final String wallCornerBottomLeft = 'assets/village_package/structure/wall_corner_bottom_left.png';
  final String wallCornerBottomRight = 'assets/village_package/structure/wall_corner_bottom_right.png';

  final String townHallImage = 'assets/village_package/structure/town_center.png';
  final String barracks = 'assets/village_package/structure/barracks.png';
  final String farm = 'assets/village_package/structure/medievalStructure_19.png';


  final String soldier = 'assets/village_package/unit/soldier1.png';

  final String rock = 'assets/village_package/environment/medievalEnvironment_07.png';
  final String rockTwo = 'assets/village_package/environment/medievalEnvironment_08.png';




  // Define the grid
  int gridSizeWidth = 1; // times 2 on the view
  int gridSizeHeight = 1; // times 4 on the view
  List<List<Tile>> tileMap = [];
  List<List<List<String>>> gridTiles = []; // Now each cell contains a list of images

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final tileSize = 40.0; // Replace this with your actual tile size
    gridSizeWidth = (screenWidth / tileSize).floor();
    gridSizeHeight = (screenHeight / tileSize).floor();

    // Initially all tiles have just a grass layer
    gridTiles = List<List<List<String>>>.generate(gridSizeHeight, (i) =>
    List<List<String>>.generate(gridSizeWidth, (j) => [grassImage]));

    tileMap = List<List<Tile>>.generate(gridSizeHeight, (i) =>
    List<Tile>.generate(gridSizeWidth, (j) => Tile(villageId: 1, rowNum: i, columnNum: j, contentType: 'miscObject', contentId: 0)));

    _populateVillage();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFb87a3d),
        title: Text('Your Village'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: GridView.builder(
          itemCount: gridSizeWidth * gridSizeHeight,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSizeWidth, // This controls the number of tiles in a row.
          ),
          itemBuilder: (BuildContext context, int index) {
            final row = index ~/ gridSizeWidth;
            final column = index % gridSizeWidth;
            return GestureDetector(
              onTap: () {
                // Add a building layer on top of the existing layers
                setState(() {
                  print(row);
                  print(column);
                  if (row > 8){
                    // only place tile if it has the overwritable property set to 1
                    // if(isTileOverwritable(row, column)){
                    //   placeElement(soldier, row, column);
                    // }
                  }
                  //gridTiles[row][column].add(wallVertical);
                });
              },
              child: Stack( // Use a stack to overlay multiple images
                fit: StackFit.expand, // To make the images fill up the whole grid tile
                children: gridTiles[row][column].map((image) => Image.asset(image, fit: BoxFit.cover)).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // Add a building to a specific location
  void placeElement(String image, int row, int column) {
    print("placing element:");
    print(image);
    setState(() {
      gridTiles[row][column].add(image);
    });
  }

  void _populateVillage() async {
    final tiles = await fetchTilesFromDB();
    for (final tile in tiles) {
      // print(tile.rowNum);
      // print(tile.columnNum);
      placeElement(rock, tile.rowNum, tile.columnNum);
      tileMap[tile.rowNum][tile.columnNum] = tile;
    }
  }

  Future<List<Tile>> fetchTilesFromDB() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('tiles');

    return List.generate(maps.length, (i) {
      return Tile(
        id: maps[i]['id'],
        villageId: maps[i]['village_id'],
        rowNum: maps[i]['row_num'],
        columnNum: maps[i]['column_num'],
        contentType: maps[i]['content_type'],
        contentId: maps[i]['content_id'],
      );

    });
  }

  // bool isTileOverwritable(int row, int column) {
  //   final tile = tileMap[row][column];
  //   return tile.overwritable == 1;
  // }


}
