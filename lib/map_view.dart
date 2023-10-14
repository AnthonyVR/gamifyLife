import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habit/barracks_view.dart';
import 'package:habit/farm_view.dart';
import 'package:habit/models/attack.dart';
import 'package:habit/villageAppBar.dart';
import 'package:habit/village_view.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';
import 'models/unit.dart';
import 'models/village.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {

  final String grassImage = 'assets/village_package/tiles/medievalTile_57.png';
  final String rock = 'assets/village_package/environment/medievalEnvironment_07.png';

  int gridSizeWidth = 30;
  int gridSizeHeight = 30;
  List<List<Map<String, dynamic>>> tileMap = [];

  int currentRow = 0;
  int currentColumn = 0;

  int selectedVillageId = 1;

  Offset? _tapPosition;

  ScrollController _horizontalController = ScrollController();
  ScrollController _verticalController = ScrollController();

  final coordinatesDisplayKey = GlobalKey<_CoordinatesDisplayState>();

  Village? _village;
  late Future<Village?> _villageFuture;

  @override
  void initState() {
    super.initState();
    _villageFuture = Village.getVillageById(1);

    _horizontalController.addListener(() {
      final newColumn = (_horizontalController.offset / 60.0).floor() + 3;
      if (newColumn != currentColumn) {
        currentColumn = newColumn;
        coordinatesDisplayKey.currentState?.updateCoordinates(currentRow, currentColumn);
      }
    });

    _verticalController.addListener(() {
      final newRow = (_verticalController.offset / 60.0).floor() + 6;
      if (newRow != currentRow) {
        currentRow = newRow;
        coordinatesDisplayKey.currentState?.updateCoordinates(currentRow, currentColumn);
      }
    });


  }


  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const tileSize = 40.0;

    // gridSizeWidth = (screenWidth / tileSize).floor();
    // gridSizeHeight = (screenHeight / tileSize).floor();

    tileMap = List.generate(gridSizeHeight,
            (i) => List.generate(gridSizeWidth, (j) => {}));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FutureBuilder<Village?>(
            future: _villageFuture,
            builder: (BuildContext context, AsyncSnapshot<Village?> villageSnapshot) {
              if (villageSnapshot.connectionState == ConnectionState.done) {
                if (!villageSnapshot.hasData || villageSnapshot.data == null) {
                  return Center(child: Text('Error loading map!'));
                }

                _village = villageSnapshot.data; // Assign to the local variable

                return FutureBuilder<Map<int, Map<int, Map<String, dynamic>>>>(
                  future: Village.fetchVillages(),
                  builder: (BuildContext context, AsyncSnapshot<Map<int, Map<int, Map<String, dynamic>>>> tileSnapshot) {
                    if (tileSnapshot.connectionState == ConnectionState.done) {
                      if (!tileSnapshot.hasData) {
                        return Center(child: Text('Error loading tiles!'));
                      }

                      WidgetsBinding.instance!.addPostFrameCallback((_) {
                        // Center the map vertically
                        _verticalController.jumpTo(
                            (_verticalController.position.maxScrollExtent / 1.5) - (MediaQuery.of(context).size.height / 6)
                        );

                        // Center the map horizontally
                        _horizontalController.jumpTo(
                            (_horizontalController.position.maxScrollExtent / 1.8) - (MediaQuery.of(context).size.width / 8)
                        );
                      });

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
          CoordinatesDisplay(key: coordinatesDisplayKey, row: currentRow, column: currentColumn),
        ],
      )
    );
  }

  Widget _buildTileGridView(Map<int, Map<int, Map<String, dynamic>>> tileMap) {
    return SingleChildScrollView(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Container(
          width: gridSizeWidth * 60.0,
          height: gridSizeHeight * 60.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(grassImage),
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: gridSizeWidth * gridSizeHeight,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSizeWidth,
            ),
            itemBuilder: (BuildContext context, int index) {
              final row = index ~/ gridSizeWidth;
              final column = index % gridSizeWidth;

              String? imagePath;
              if (tileMap.containsKey(row) && tileMap[row]!.containsKey(column)) {

                if(tileMap[row]![column]!['owned'] == 1){
                  if(tileMap[row]![column]!['id'] == selectedVillageId){
                    imagePath = 'assets/village_walled_selected.png';
                  } else {
                    imagePath = 'assets/village_walled.png';
                  }
                } else {
                  imagePath = 'assets/village_walled_enemy.png';
                }
              }

              return GestureDetector(
                onTapDown: (details) => _tapPosition = details.globalPosition,
                onTap: () {
                  if (_tapPosition != null && imagePath != null) {

                    if(tileMap[row]![column]!['owned'] == 1){
                      print("eeeee");
                      _showOwnedVillagePopup(context, _tapPosition!, tileMap[row]![column]!);
                    } else {
                      _showEnemyVillagePopup(context, _tapPosition!, tileMap[row]![column]!);
                    }
                  }
                },
                child: imagePath != null ? Image.asset(imagePath) : Text(""),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showOwnedVillagePopup(BuildContext context, Offset offset, Map<String, dynamic> tileData) async {
    final RenderBox overlay = Overlay.of(context)?.context.findRenderObject() as RenderBox;

    print("tiledata");
    print(tileData['name']);

    Village? village = await  Village.getVillageById(tileData['id']);
    List<Unit>? units = await village.getUnits();

    showMenu(
      color: Colors.white30,
      context: context,
      position: RelativeRect.fromRect(
        offset & Size(40, 40), // assuming each tile is 40x40
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'info',
          child: Text("${tileData['name']} (${tileData['columnNum']}, ${tileData['rowNum']})"),
        ),
        PopupMenuItem(
          value: 'option1',
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                selectedVillageId = tileData['id'];
              });
              },
            child: Text("Select"),
          ),
        ),
        PopupMenuItem(
          value: 'Enter village',
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VillageView(villageId: tileData['id']),
                    fullscreenDialog: true, // make the page full screen
                  ),
                );
              });
            },
            child: Text("Enter village"),
          ),
        ),
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/coins.svg',
                width: 26,
                height: 26,
              ),
              SizedBox(width: 5,),
              Text("${tileData['coins']}", style: TextStyle(fontSize: 20))
            ],
          ),
        ),
        ...units.map((unit) {
          return PopupMenuItem(
            value: unit.id,
            child: Row(
              children: <Widget>[
                Image.asset(unit.image, width: 24, height: 24), // adjust width and height as needed
                SizedBox(width: 2), // Adds some spacing between image and text
                Text("${unit.name}: ${unit.amount}"),
              ],
            ),
          );
        }).toList(),
      ],
      elevation: 8.0,
    );
  }

  Future<void> _showEnemyVillagePopup(BuildContext context, Offset offset, Map<String, dynamic> tileData) async {
    final RenderBox overlay = Overlay.of(context)?.context.findRenderObject() as RenderBox;

    print("tiledata");
    print(tileData['name']);

    showMenu(
      color: Colors.white24,
      context: context,
      position: RelativeRect.fromRect(
        offset & Size(40, 40), // assuming each tile is 40x40
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'info',
          child: Text("${tileData['name']} (${tileData['columnNum']}, ${tileData['rowNum']})"),
        ),
        PopupMenuItem(
          value: 'option1',
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return FutureBuilder<List<Unit>?>(
                    future: _fetchUnits(selectedVillageId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No units available');
                      } else {
                        return UnitsPopup(
                          units: snapshot.data!,
                          selectedVillageId: selectedVillageId,
                          destinationVillageId: tileData['id'],
                        );
                      }
                    },
                  );
                },
              );
            },

            child: const Text("attack"),
          ),
        ),
      ],
      elevation: 8.0,
    );
  }

  Future<List<Unit>?> _fetchUnits(int villageId) async {
    Village? village = await Village.getVillageById(villageId);
    return village?.getUnits();
  }

}




class UnitsPopup extends StatefulWidget {
  final List<Unit> units;
  final int selectedVillageId;
  final int destinationVillageId;

  UnitsPopup({
    required this.units,
    required this.selectedVillageId,
    required this.destinationVillageId,
  });

  @override
  _UnitsPopupState createState() => _UnitsPopupState();
}

class _UnitsPopupState extends State<UnitsPopup> {
  late Map<Unit, int> selectedUnitsMap;

  @override
  void initState() {
    super.initState();
    selectedUnitsMap = {for (var unit in widget.units) unit: unit.amount};
  }


  void _onAttackPressed() {
    List<Map<String, dynamic>> attackDetails = selectedUnitsMap.entries
        .map((entry) => {
      'unit': entry.key,
      'amount': entry.value,
    })
        .where((detail) => detail['amount'] as int > 0)
        .toList();

    // Call the attackEnemyVillage function with the list of selected units and their amounts
    Attack.attackEnemyVillage(widget.selectedVillageId, widget.destinationVillageId, attackDetails);
    //attackEnemyVillage(attackDetails);

    print('Attack details: $attackDetails');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.units.map((unit) {
            return ListTile(
              title: Text(unit.name),
              subtitle: Row(
                children: [
                  Text('Amount:'),
                  SizedBox(width: 15),
                  DropdownButton<int>(
                    value: selectedUnitsMap[unit],
                    items: List.generate(unit.amount! + 1, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text('$index'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        selectedUnitsMap[unit] = value!;
                      });
                    },
                  )
                ],
              ),
              onTap: () {
                Navigator.pop(context, {'unit': unit, 'amount': selectedUnitsMap[unit]});
              },
            );
          }).toList(),
          ElevatedButton(
            onPressed: _onAttackPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ATTACK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}





class CoordinatesDisplay extends StatefulWidget {
  final int row;
  final int column;

  CoordinatesDisplay({Key? key, required this.row, required this.column}) : super(key: key);

  @override
  _CoordinatesDisplayState createState() => _CoordinatesDisplayState();
}
class _CoordinatesDisplayState extends State<CoordinatesDisplay> {
  int _row;
  int _column;

  _CoordinatesDisplayState()
      : _row = 0,
        _column = 0;

  @override
  void initState() {
    super.initState();
    _row = widget.row;
    _column = widget.column;
  }

  void updateCoordinates(int newRow, int newColumn) {
    setState(() {
      _row = newRow;
      _column = newColumn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10.0,
      right: 10.0,
      child: Container(
        padding: EdgeInsets.all(8.0),
        color: Colors.black38,
        child: Text(
          'x: $_column, y: $_row',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}



