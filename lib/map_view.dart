import 'package:flutter/material.dart';
import 'package:habit/barracks_view.dart';
import 'package:habit/farm_view.dart';
import 'package:habit/villageAppBar.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';
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
                imagePath = 'assets/village_walled.png';
              }

              return GestureDetector(
                onTapDown: (details) => _tapPosition = details.globalPosition,
                onTap: () {
                  if (_tapPosition != null && imagePath != null) {
                    _showTilePopup(context, _tapPosition!, tileMap[row]![column]!);
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

  void _showTilePopup(BuildContext context, Offset offset, Map<String, dynamic> tileData) {
    final RenderBox overlay = Overlay.of(context)?.context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        offset & Size(40, 40), // assuming each tile is 40x40
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: Text('Tile Information'),
          value: 'info',
        ),
        PopupMenuItem(
          child: Text('Village: ${tileData['villageName']}'), // adjust as per your tile data
          value: 'village',
        ),
        // ... Add more items if needed
      ],
      elevation: 8.0,
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



