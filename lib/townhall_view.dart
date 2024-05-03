import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit/villageAppBar.dart';
import 'package:sqflite/sqflite.dart';
import 'models/settings.dart';
import 'models/village.dart';
import 'package:habit/services/database_helper.dart';


class TownhallView extends StatefulWidget {

  TownhallView({required this.villageId});
  final int villageId;

  @override
  _TownhallViewState createState() => _TownhallViewState();
}

class _TownhallViewState extends State<TownhallView> {

  Settings? _settings;
  Village? village;

  int currentTownHallLevel = 0; // This will be fetched from the database.

  @override
  void initState() {
    super.initState();
    fetchVillageData();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VillageAppBar(
        getVillage: _getVillage,
        titleText: 'Town Hall',
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/town_hall_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 90,
                columns: [
                  DataColumn(label: _styledText('Level')),
                  DataColumn(label: _styledText('Cost')),
                  DataColumn(label: _styledText('Upgrade')),
                ],
                rows: List.generate(20, (index) {
                  return DataRow(cells: [
                    DataCell(_styledText('${index + 1}')),
                    DataCell(Row(
                      children: [
                        SvgPicture.asset(
                          'assets/coins.svg',
                          width: 13,
                          height: 13,
                        ),
                        _styledText(getCost(index + 1).toStringAsFixed(0)),
                      ],
                    )),
                    DataCell(IconButton(
                      icon: Icon(
                        (index + 1) <= currentTownHallLevel ? Icons.check : Icons.arrow_circle_up_sharp,
                        color: (index + 1) <= currentTownHallLevel ? Colors.green : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        if ((index) == currentTownHallLevel) {
                          // Only allow upgrade if the level is 1 greater than the current townhall level
                          setState(() async {
                            final db = await DatabaseHelper.instance.database;
                            village?.upgradeBuildingLevel(db, 'town_hall');
                            currentTownHallLevel = index + 1; // Placeholder logic, you can replace with db update logic.
                          });
                        }
                      },
                      tooltip: "Upgrade",
                    )),
                  ]);                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadSettings() async {
    Database db = await DatabaseHelper.instance.database;

    _settings = await Settings.getSettingsFromDB(db);
    setState(() {});
  }

  int getCost(int level) {

    const double initialCost = 10;
    final double? costMultiplier = _settings?.costMultiplier;

    return (initialCost * pow(costMultiplier!, level - 1)).round();

  }

  Widget _styledText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22.0,
        shadows: [
          Shadow(
            offset: Offset(1.0, 1.0),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Future<Village?> _getVillage() async {
    return await Village.getVillageById(widget.villageId);
  }

  Future<void> fetchVillageData() async {
    village = await _getVillage();
    int? level = await village?.getBuildingLevel('town_hall');

    setState(() {
      currentTownHallLevel = level!; // Ensure you handle the possibility of level being null properly.
    });
  }

}
