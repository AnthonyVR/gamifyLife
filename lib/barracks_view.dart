import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sqflite/sqflite.dart';
import '../models/unit.dart';
import 'models/village.dart';
import 'models/settings.dart';
import 'package:habit/services/database_helper.dart';


class BarracksView extends StatefulWidget {

  BarracksView({required this.villageId});
  final int villageId;

  @override
  _BarracksViewState createState() => _BarracksViewState();

}

class _BarracksViewState extends State<BarracksView> {

  Settings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }


  void _loadSettings() async {
    Database db = await DatabaseHelper.instance.database;

    _settings = await Settings.getSettingsFromDB(db);
    setState(() {});
  }

  Future<List<Unit>> fetchUnits() async {
    Village? village = await Village.getVillageById(widget.villageId);

    List<Unit>? units = await village.getUnits();
    return units;
  }

  Future<List<Unit>> fetchAllUnits() async {
    Village? village = await Village.getVillageById(widget.villageId);

    // Fetch the base units from the village
    List<Unit>? units = await village.getUnits();
    if (units == null) {
      return [];  // Return an empty list if there are no base units
    }

    // Initialize a map to quickly access units by their IDs
    Map<int, Unit> unitMap = { for (var unit in units) unit.id!: unit };

    // Fetch additional units and their amounts from the village
    List<Unit>? unitsInVillage = await village.getUnitsInVillage();

    print('UNITMAPPsssssssssssssP');
    for (var unit in unitsInVillage){
      print(unit.name);
      print(unit.amount);
    }


    if (unitsInVillage != null) {
      for (Unit additionalUnit in unitsInVillage) {
        if (additionalUnit.id != null && unitMap.containsKey(additionalUnit.id)) {
          // Add the amounts to the units in the base list
          unitMap[additionalUnit.id]?.amount += additionalUnit.amount;
        }
      }
    }

    // Return the updated list of units from the map
    print('UNITMAPPP');
    for (var unit in unitMap.values){
      print(unit.name);
      print(unit.amount);
    }
    return unitMap.values.toList();
  }


  Future<void> levelUpUnit(int? id) async {
    if (id == null) {
      throw Exception();
    }

    Village? village = await Village.getVillageById(widget.villageId);

    if (village == null) {
      throw Exception('Village with ID ${widget.villageId} not found');
    }

    village.levelUpUnit(id);
  }

  Future<void> buyUnit(int? id) async {
    if (id == null) {
      throw Exception();
    }

    Village? village = await Village.getVillageById(widget.villageId);

    if (village == null) {
      throw Exception('Village with ID ${widget.villageId} not found');
    }

    village.buyUnit(id);
  }

  Future<Village?> _getVillage() async {
    return await Village.getVillageById(widget.villageId);
  }


  Future<Village?> _getVillageCapacity() async {
    return await Village.getVillageById(widget.villageId);
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // This will hide the back button
          backgroundColor: Colors.brown[700],
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
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/coins.svg',
                          width: 25,
                          height: 25,
                        ),
                        SizedBox(width: 5,),
                        Text("${villageSnapshot.data?.coins}", style: TextStyle(fontSize: 28),),
                      ],
                    ),
                    Text("Barracks"),
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
          bottom: TabBar(
            tabs: [
              Tab(text: 'Recruitment'),
              Tab(text: 'Training'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRecruitmentView(),
            _buildTrainingView(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentView() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/barracks_view.webp',  // Replace this with the path to your image
            fit: BoxFit.cover, // This will make sure the image covers the entire view
          ),
        ),

        // Content on top of the image
        FutureBuilder<List<Unit>>(
          future: fetchUnits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error fetching units.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No units available.'));
            } else {
              List<Unit> units = snapshot.data!;
              return ListView.builder(
                itemCount: units.length,
                itemBuilder: (BuildContext context, int index) {
                  Unit unit = units[index];
                  return Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.apply(
                        bodyColor: Colors.white,  // Default text color.
                        displayColor: Colors.red,  // Default text color for headings, titles, etc.
                      ),
                    ),
                    child: Card(
                      color: Colors.brown[800],
                      elevation: 5.0,
                      margin: const EdgeInsets.all(10.0),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            // 1st Column: Unit Name and Amount
                            Expanded(
                              flex: 2, // Allocate more space for the merged column
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row( // Wrap the Image and the Amount Text inside a Row
                                    crossAxisAlignment: CrossAxisAlignment.center, // Ensure items in the row are vertically centered
                                    children: [
                                      Text(
                                        '${unit.amount}',
                                        style: TextStyle(
                                          fontSize: 40, // Make the amount stand out
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Image.asset(
                                        unit.image,
                                        width: 60,
                                        height: 60,
                                      ),
                                      SizedBox(width: 10.0), // Provides a little spacing between image and text
                                    ],
                                  ),
                                  Text(
                                    '${unit.name} (lvl.${unit.level})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 2nd Column: Attack, Defence, and Level Up
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Atk: ${unit.offence}'),
                                  Text('Def: ${unit.defence}'),
                                  SizedBox(height: 12.0),
                                  Text('Loot: ${unit.loot}'),
                                ],
                              ),
                            ),
                            // 3rd Column: Create and Place in Village buttons
                            // 3rd Column: Create and Place in Village buttons
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outlined, size: 50, color: Colors.green), // Adjust size and color as needed
                                        onPressed: () async {
                                          await buyUnit(unit.id);
                                          setState(() {});
                                        },
                                        color: Colors.green, // This will be the color of the button's background
                                        padding: EdgeInsets.zero,
                                      ),
                                      SizedBox(width: 10.0),
                                      SvgPicture.asset(
                                        'assets/coins.svg',
                                        width: 13,
                                        height: 13,
                                      ),
                                      SizedBox(width: 3.0),
                                      Text('${unit.cost}'),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, {'unit_id': unit.id});
                                      //placeUnitInVillage(unit.id);
                                    },
                                    child: Text('Place in Village'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  );
                },
              );
            }
          },
        ),
      ],
    );



    // return FutureBuilder<List<Unit>>(
    //   future: fetchUnits(),
    // );
  }

  Widget _buildTrainingView() {

    final double? costMultiplier = _settings?.costMultiplier;

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/barracks_view.webp',  // Replace this with the path to your image
            fit: BoxFit.cover, // This will make sure the image covers the entire view
          ),
        ),

        // Content on top of the image
        FutureBuilder<List<Unit>>(
          future: fetchAllUnits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error fetching units.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No units available.'));
            } else {
              List<Unit> units = snapshot.data!;
              return ListView.builder(
                itemCount: units.length,
                itemBuilder: (BuildContext context, int index) {
                  Unit unit = units[index];

                  return Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: Colors.white,  // Default text color.
                          displayColor: Colors.red,  // Default text color for headings, titles, etc.
                        ),
                      ),
                      child: Card(
                        color: Colors.brown[700],
                        elevation: 5.0,
                        margin: const EdgeInsets.all(10.0),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            children: [
                              // 1st Column: Unit Name and Amount
                              Expanded(
                                flex: 2, // Allocate more space for the merged column
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      unit.image,
                                      width: 60,
                                      height: 60,
                                    ),
                                    Text(
                                      '${unit.name} (lvl.${unit.level})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 2nd Column: Attack, Defence, and Level Up
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Atk: ${unit.offence} (+${(unit.initialOffence * pow(costMultiplier!, unit.level )).round() - (unit.initialOffence * pow(costMultiplier!, unit.level -1)).round()})'),
                                    Text('Def: ${unit.defence} (+${(unit.initialDefence * pow(costMultiplier!, unit.level )).round() - (unit.initialDefence * pow(costMultiplier!, unit.level -1)).round()})'),
                                    SizedBox(height: 10),
                                    Text('Loot: ${unit.loot} (+${(unit.initialLoot * pow(costMultiplier!, unit.level )).round() - (unit.initialLoot * pow(costMultiplier!, unit.level -1)).round()})'),
                                    SizedBox(height: 8.0),
                                  ],
                                ),
                              ),
                              // 3rd Column: Create and Place in Village buttons
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        await levelUpUnit(unit.id);
                                        setState(() {});
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.green),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                        children: [
                                          Text('Level Up '),
                                          Text(
                                            '${(unit.initialCost * pow(costMultiplier, (unit.level - 1)) + unit.initialCost * pow(costMultiplier, (unit.level))).round()} coins',
                                            //(unit.cost * pow(costMultiplier!, unit.level - 1)).round()
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.yellow[600],
                                            ),
                                          ),
                                          Text(
                                            '+${unit.amount * (unit.initialCost * pow(costMultiplier, (unit.level)) - unit.initialCost * pow(costMultiplier, (unit.level - 1)) ).round()} coins',
                                            //(unit.cost * pow(costMultiplier!, unit.level - 1)).round()
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.yellow[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  );
                },
              );
            }
          },
        ),
      ],
    );

  }

}
