import 'package:flutter/material.dart';
import 'package:habit/barracks_view.dart';
import 'package:habit/farm_view.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';
import 'models/village.dart';

class VillageView extends StatefulWidget {
  const VillageView({Key? key}) : super(key: key);

  @override
  _VillageViewState createState() => _VillageViewState();
}

class _VillageViewState extends State<VillageView> {

  final String grassImage = 'assets/village_package/tiles/medievalTile_57.png';
  final String rock = 'assets/village_package/environment/medievalEnvironment_07.png';

  int? _unitIdToPlace;

  int gridSizeWidth = 1;
  int gridSizeHeight = 1;
  List<List<Map<String, dynamic>>> tileMap = [];

  Village? _village;
  late Future<Village?> _villageFuture;

  @override
  void initState() {
    super.initState();
    _villageFuture = Village.getVillageById(1);
  }

  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const tileSize = 40.0;

    gridSizeWidth = (screenWidth / tileSize).floor();
    gridSizeHeight = (screenHeight / tileSize).floor();

    // print("gridsizewidth");
    // print(gridSizeWidth);
    //
    // print("gridsizeheight");
    // print(gridSizeHeight);

    tileMap = List.generate(gridSizeHeight,
            (i) => List.generate(gridSizeWidth, (j) => {}));


    //_populateVillage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFb87a3d),
        title: FutureBuilder<Village?>(
          future: _getVillage(),
          builder: (context, villageSnapshot) {
            if (villageSnapshot.connectionState == ConnectionState.done) {
              if (villageSnapshot.hasError) {
                return Text('Error');
              }
              if (!villageSnapshot.hasData || villageSnapshot.data == null) {
                return Text('No Village Data');
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(villageSnapshot.data!.name),
                  FutureBuilder<int?>(
                    future: villageSnapshot.data!.getPopulation(),
                    builder: (context, populationSnapshot) {
                      if (populationSnapshot.connectionState == ConnectionState.done) {
                        if (!populationSnapshot.hasData || populationSnapshot.data == null) {
                          return Text('(No population data)');
                        }
                        return FutureBuilder<int?>(
                          future: villageSnapshot.data!.getCapacity(),
                          builder: (context, capacitySnapshot) {
                            if (capacitySnapshot.connectionState == ConnectionState.done) {
                              if (!capacitySnapshot.hasData || capacitySnapshot.data == null) {
                                return Text('${populationSnapshot.data} / (No capacity data)');
                              }
                              return Text('${populationSnapshot.data} / ${capacitySnapshot.data}');
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  )
                ],
              );

            } else {
              return CircularProgressIndicator();
            }
          },
        ),
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

            child: imagePath != null
                ? Image.asset(imagePath, fit: BoxFit.cover)
                : Container(),  // Display an empty container if there's no tile.
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
    if (id == null) {
      throw Exception();
    }

    Village? village = await Village.getVillageById(1);
    if (village == null) {
      throw Exception('Village with ID ${1} not found');
    }

    print("placing now");
    print(row);
    print(column);
    village.placeUnitInVillage(id, row, column);
  }

  Future<Village?> _getVillage() async {
    final db = await DatabaseHelper.instance.database;
    return await Village.getVillageById(1);
  }
}
