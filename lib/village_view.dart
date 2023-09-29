import 'package:flutter/material.dart';
import 'package:habit/barracks_view.dart';
import 'package:habit/farm_view.dart';
import 'package:habit/villageAppBar.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';
import 'models/village.dart';

class VillageView extends StatefulWidget {
  const VillageView({Key? key}) : super(key: key);

  @override
  _VillageViewState createState() => _VillageViewState();
}

class _VillageViewState extends State<VillageView> {

  int villageId = 1;

  final String grassImage = 'assets/village_package/tiles/medievalTile_57.png';
  final String rock = 'assets/village_package/environment/medievalEnvironment_07.png';

  int? _unitIdToPlace;
  int? _initialRow;
  int? _initialColumn;

  int gridSizeWidth = 1;
  int gridSizeHeight = 1;
  List<List<Map<String, dynamic>>> tileMap = [];

  Village? _village;
  late Future<Village?> _villageFuture;

  @override
  void initState() {
    super.initState();
    _villageFuture = Village.getVillageById(1);

    //this code should be changed later to implement multiple village functionality!
    villageId = 1;
  }

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const tileSize = 40.0;

    gridSizeWidth = (screenWidth / tileSize).floor();
    gridSizeHeight = (screenHeight / tileSize).floor();

    tileMap = List.generate(gridSizeHeight,
            (i) => List.generate(gridSizeWidth, (j) => {}));


    //_populateVillage();
    // print("creating initial village");
    // Village.createInitialVillage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VillageAppBar(
        getVillage: _getVillage,
      ),
      body: FutureBuilder<Village?>(
        future: _villageFuture,
        builder: (BuildContext context, AsyncSnapshot<Village?> villageSnapshot) {
          if (villageSnapshot.connectionState == ConnectionState.done) {
            if (!villageSnapshot.hasData || villageSnapshot.data == null) {
              return Center(child: Text('Error loading village!'));
            }

            _village = villageSnapshot.data; // Assign to the local variable

            return FutureBuilder<Map<int, Map<int, Map<String, dynamic>>>>(
              future: _village!.fetchTiles(),
              builder: (BuildContext context, AsyncSnapshot<Map<int, Map<int, Map<String, dynamic>>>> tileSnapshot) {
                if (tileSnapshot.connectionState == ConnectionState.done) {
                  if (!tileSnapshot.hasData) {
                    return Center(child: Text('Error loading tiles!'));
                  }
                  // Render the GridView
                  Map<int, Map<int, Map<String, dynamic>>> tileMap = tileSnapshot.data!;
                  return _buildTileGridView(tileMap);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildTileGridView(Map<int, Map<int, Map<String, dynamic>>> tileMap) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(grassImage),
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: GridView.builder(
        itemCount: gridSizeWidth * gridSizeHeight,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSizeWidth,
        ),
        itemBuilder: (BuildContext context, int index) {
          final row = index ~/ gridSizeWidth;
          final column = index % gridSizeWidth;

          String? imagePath;
          if (tileMap.containsKey(row) &&
              tileMap[row]!.containsKey(column) &&
              tileMap[row]![column]!.containsKey('imagePath')) {
            imagePath = tileMap[row]![column]!['imagePath'];
          }

          return DragTarget<Map<String, dynamic>>(
            builder: (context, candidateData, rejectedData) {
              return InkWell(
                onTap: () async {
                  print(row);
                  print(column);
                  if(tileMap.containsKey(row) && tileMap[row]!.containsKey(column)) {
                    String objectName = tileMap[row]![column]!['objectName'];
                    if (objectName == 'barracks') {
                      await _navigateToBarracksAndGetUnit();

                    } else if (objectName == 'farm') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FarmView(),
                          fullscreenDialog: true, // make the page full screen
                        ),
                      );
                    }
                  } else {

                    // For when you want to place a unit in the village, coming from the barracks
                    if (_unitIdToPlace != null) {
                      placeUnitInVillage(_unitIdToPlace, row, column);

                      setState(() {
                        _unitIdToPlace = null;
                      });
                      await _navigateToBarracksAndGetUnit();

                    }
                  }
                },

                onLongPress: () async {

                  if(tileMap.containsKey(row) && tileMap[row]!.containsKey(column)) {
                    String contentType = tileMap[row]![column]!['contentType'];
                    if (contentType == 'unit') {
                      print("logic");
                    }
                  }
                },
                child: tileMap.containsKey(row) && tileMap[row]!.containsKey(column)
                    ? LongPressDraggable<Map<String, dynamic>>(
                  data: {
                    'row': row,
                    'column': column,
                    ...tileMap[row]![column]!,
                  },
                  child: Image.asset(tileMap[row]![column]!['imagePath'], fit: BoxFit.cover),
                  feedback: Material(
                    child: Image.asset(tileMap[row]![column]!['imagePath'], fit: BoxFit.cover),
                    elevation: 4.0,
                  ),
                  onDragStarted: () {
                    _initialRow = row;
                    _initialColumn = column;
                    print("setting initiali row");
                    print(_initialRow);
                  },
                )
                    : Container(), // Display an empty container if there's no tile.
              );
            },
            onWillAccept: (data) {
              // Decide if you will accept the dragged unit on this tile
              return !tileMap.containsKey(row) || !tileMap[row]!.containsKey(column) || (row == 3 && column == 6);
            },
            onAccept: (data) async {

              print('accepting!');

              // Handle the accepted drag. Update your state to move the unit to the new position.

              if (_initialRow != null && _initialColumn != null) {

                if(row == 3 && column == 6){
                  print("removing unit");
                  await removeUnitFromVillage(_initialRow!, _initialColumn!);
                } else{
                  await moveUnit(1, row, column);

                }
                _initialRow = null;
                _initialColumn = null;
              }

              setState(() {

                // ... any additional logic you might want to add for handling the drop

              });
            },
          );

        },
      ),
    );
  }

  // This function makes you go to the barracks and is necessary for
  // being able to place a unit in the village. It adds a listener for
  // a unit id, to make it possible to use the place unit button from the barracks.
  Future<void> _navigateToBarracksAndGetUnit() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarracksView(villageId: 1),
        fullscreenDialog: true, // make the page full screen
      ),
    );

    if (result != null && result['unit_id'] != null) {
      setState(() {
        _unitIdToPlace = result['unit_id'];
        print('unit to place');
        print(_unitIdToPlace);
      });
    }
  }

  Future<void> placeUnitInVillage(int? id, int row, int column) async {

    _village?.placeTileInVillage(id!, row, column, "unit");
  }

  Future<void> removeUnitFromVillage(int row, int column) async {

    Tile? selectedUnit = await _village?.getTileByRowAndColumn(_initialRow!, _initialColumn!);

    if(selectedUnit?.contentType == 'unit') {
      _village?.removeTile(selectedUnit!);
    }
  }


  Future<void> moveUnit(int id, int destinationRow, int destinationColumn) async {

    Tile? selectedUnit = await _village?.getTileByRowAndColumn(_initialRow!, _initialColumn!);

    if(selectedUnit?.contentType == 'unit'){
      await _village?.moveTile(selectedUnit!, destinationRow, destinationColumn);
    }

  }

  Future<Village?> _getVillage() async {
    return await Village.getVillageById(1);
  }
}
