import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit/villageAppBar.dart';
import 'package:sqflite/sqflite.dart';
import 'models/settings.dart';
import 'models/village.dart';
import 'package:habit/services/database_helper.dart';


class FarmView extends StatefulWidget {

  FarmView({required this.villageId});
  final int villageId;

  @override
  _FarmViewState createState() => _FarmViewState();
}

class _FarmViewState extends State<FarmView> {

  Settings? _settings;
  Village? village;

  int currentFarmLevel = 0; // This will be fetched from the database.

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
        titleText: 'Farm',
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/farm_view.jpg'),
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
                columnSpacing: 45,
                columns: [
                  DataColumn(label: _styledText('Level')),
                  DataColumn(label: _styledText('Capacity')),
                  DataColumn(label: _styledText('Cost')),
                  DataColumn(label: _styledText('Upgrade')),
                ],
                rows: List.generate(20, (index) {
                  return DataRow(cells: [
                    DataCell(_styledText('${index + 1}')),
                    DataCell(_styledText(getCapacity(index + 1).toStringAsFixed(0))),
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
                        (index + 1) <= currentFarmLevel ? Icons.check : Icons.arrow_circle_up_sharp,
                        color: (index + 1) <= currentFarmLevel ? Colors.green : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () async {
                        if ((index) == currentFarmLevel) {
                          // Only allow upgrade if the level is 1 greater than the current farm level
                          final db = await DatabaseHelper.instance.database;
                          village?.upgradeBuildingLevel(db, 'farm', getCost(index + 1));
                          currentFarmLevel = index + 1; // Placeholder logic, you can replace with db update logic.

                          setState(() {

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

    const double initialCost = 80;
    final double? costMultiplier = _settings?.costMultiplier;

    return (initialCost * pow(costMultiplier!, level - 1)).round();
  }

  int getCapacity(int level) {
    return 5 + pow(3, pow(level, 0.5)).round();
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
    int? level = await village?.getBuildingLevel('farm');

    setState(() {
      currentFarmLevel = level!; // Ensure you handle the possibility of level being null properly.
    });
  }

}
