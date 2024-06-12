// attack_simulator.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit/models/attack.dart';
import 'package:habit/models/unit.dart';
import 'package:intl/intl.dart';

class AttackSimulator extends StatefulWidget {
  @override
  _AttackSimulatorState createState() => _AttackSimulatorState();
}

class _AttackSimulatorState extends State<AttackSimulator> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sourceVillageIdController = TextEditingController();
  final TextEditingController _destinationVillageIdController = TextEditingController();
  List<Map<String, dynamic>> _sourceUnits = [];
  List<Map<String, dynamic>> _destinationUnits = [];
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeUnits();
  }

  Future<void> _initializeUnits() async {
    List<Unit> units = [
      Unit(villageId: 100000, name: "spearman", image: "assets/spearman.png", level: 1, initialOffence: 10, initialDefence: 10, offence: 10, defence: 10, amount: 0, inTransit: 0, initialCost: 20, cost: 20, speed: (25/1).round(), initialLoot: 10, loot: 10),
      Unit(villageId: 100001, name: "wizard", image: "assets/wizard.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 0, inTransit: 0, initialCost: 30, cost: 30, speed: (25/1).round(), initialLoot: 20, loot: 20),
      Unit(villageId: 100002, name: "spy", image: "assets/spy.png", level: 1, initialOffence: 0, initialDefence: 5, offence: 0, defence: 5, amount: 0, inTransit: 0, initialCost: 30, cost: 30, speed: (10/1).round(), initialLoot: 0, loot: 0),
      Unit(villageId: 100003, name: "catapult", image: "assets/catapult.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 0, inTransit: 0, initialCost: 80, cost: 80, speed: (40/1).round(), initialLoot: 50, loot: 50),
      Unit(villageId: 100004, name: "king", image: "assets/king.png", level: 1, initialOffence: 20, initialDefence: 5, offence: 20, defence: 5, amount: 0, inTransit: 0, initialCost: 500, cost: 500, speed: (60/1).round(), initialLoot: 100, loot: 100)];

    setState(() {
      _sourceUnits = units.map((unit) => {'unit': unit, 'amount': 0}).toList();
      _destinationUnits = units.map((unit) => {'unit': unit, 'amount': 0}).toList();
    });
  }

  Future<void> _simulateAttack() async {
    if (_formKey.currentState!.validate()) {
      int sourceVillageId = int.parse(_sourceVillageIdController.text);
      int destinationVillageId = int.parse(_destinationVillageIdController.text);

      DateTime now = DateTime.now();
      double distance = await Attack.calculateDistanceBetweenVillagesById(sourceVillageId, destinationVillageId);
      int slowestSpeed = Attack.calculateSlowestSpeed(_sourceUnits);
      DateTime arrivalTime = Attack.calculateArrivalTime(now, distance, slowestSpeed);

      Attack attack = Attack(
        sourceVillageId: sourceVillageId,
        destinationVillageId: destinationVillageId,
        startedAt: now,
        arrivedAt: arrivalTime,
        sourceUnitsBefore: jsonEncode(_sourceUnits),
        destinationUnitsBefore: jsonEncode(_destinationUnits),
        owned: 1,
        completed: 0,
      );

      await attack.handleOutgoingAttack();

      setState(() {
        _result = 'Attack simulation completed! Result: ${attack.outcome == 1 ? 'Player wins' : 'CPU wins'}';
      });

      showDialog(
        context: context,
        builder: (context) => _attackDetailsDialog(attack),
      );
    }
  }

  Widget _buildUnitInputField(List<Map<String, dynamic>> units, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...units.map((unitData) {
          return Row(
            children: [
              Expanded(
                child: DropdownButton<Unit>(
                  value: unitData['unit'],
                  onChanged: (Unit? newValue) {
                    setState(() {
                      unitData['unit'] = newValue!;
                    });
                  },
                  items: units.map<DropdownMenuItem<Unit>>((unitData) {
                    return DropdownMenuItem<Unit>(
                      value: unitData['unit'],
                      child: Text(unitData['unit'].name),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: unitData['amount'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                  onChanged: (value) {
                    setState(() {
                      unitData['amount'] = int.parse(value);
                    });
                  },
                ),
              ),
            ],
          );
        }).toList(),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _attackDetailsDialog(Attack attack) {
    String formatTimestamp(String timestamp) {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('d MMMM y, HH:mm:ss').format(dateTime);
    }

    if (attack.opened == 0) {
      attack.opened = 1;
      attack.updateToDb();
    }

    return Dialog(
      insetPadding: EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: attack.outcome == 0 ? Colors.red[100] : Colors.green[100],
          boxShadow: attack.opened == 1
              ? [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(8.0),
              children: [
                Center(child: Text("Sent: ${formatTimestamp(attack.startedAt.toIso8601String())}")),
                SizedBox(height: 10),
                Center(child: Text("Arrived: ${formatTimestamp(attack.arrivedAt.toIso8601String())}")),
                SizedBox(height: 10),
                Center(child: Text("Returned: ${attack.returnedAt != null ? formatTimestamp(attack.returnedAt!.toIso8601String()) : 'N/A'}")),
                SizedBox(height: 50),
                Center(child: Text("Attacker: ${attack.sourceVillageName ?? 'Unknown'}")),
                FutureBuilder<Widget>(
                  future: generateUnitsTable(attack.sourceUnitsBefore, attack.sourceUnitsAfter!, 1, attack.owned),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(child: snapshot.data!);
                    }
                  },
                ),
                SizedBox(height: 30),
                Center(child: Text("Defender: ${attack.destinationVillageName ?? 'Unknown'}")),
                FutureBuilder<Widget>(
                  future: generateUnitsTable(attack.destinationUnitsBefore!, attack.destinationUnitsAfter!, attack.outcome!, attack.owned),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(child: snapshot.data!);
                    }
                  },
                ),
                SizedBox(height: 30.0),
                Center(child: Text("Loot:")),
                SizedBox(height: 5.0),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/coins.svg',
                        width: 26,
                        height: 26,
                      ),
                      SizedBox(width: 5.0),
                      Text('${attack.loot}', style: const TextStyle(fontSize: 28)),
                    ],
                  ),
                ),
                SizedBox(height: 30.0),
                Center(child: Text("Damage to townhall: ${attack.damage}")),
                SizedBox(height: 30.0),
                attack.espionage != null
                    ? Center(
                    child: Text(
                        "Espionage: \n Coins: ${getEspionageResults(attack.espionage!)['coins']} "
                            "\n Townhall: ${getEspionageResults(attack.espionage!)['townhall']} "
                            "\n Barracks: ${getEspionageResults(attack.espionage!)['barracks']} "
                            "\n Farm: ${getEspionageResults(attack.espionage!)['farm']}"))
                    : SizedBox(width: 5.0),
              ],
            ),
            Positioned(
              top: 10.0,
              right: 10.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/luck.png', width: 50.0, height: 50.0),
                  Text(
                    "${attack.luck}",
                    style: TextStyle(
                      color: _getLuckColor(attack.luck!),
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              child: Image.asset(attack.owned == 1 ? 'assets/attack.png' : 'assets/defense.png', width: 40.0, height: 40.0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLuckColor(int luck) {
    const double minLuck = -15.0;
    const double maxLuck = 15.0;

    return Color.lerp(
      Colors.red,
      Colors.green,
      (luck.toDouble() - minLuck) / (maxLuck - minLuck),
    )!;
  }

  Future<Widget> generateUnitsTable(String unitsBeforeStr, String unitsAfterStr, int attackOutcome, int attackOwned) async {
    List<Map<String, dynamic>> unitsBefore = await decodeUnits(unitsBeforeStr);
    List<Map<String, dynamic>> unitsAfter = await decodeUnits(unitsAfterStr);

    if (unitsBefore.isEmpty) {
      return Center(child: Text('\n- No defending units - ', style: TextStyle(fontStyle: FontStyle.italic)));
    }

    List<DataColumn> columns = unitsBefore.map((unitMap) {
      return DataColumn(
        label: Image.asset(unitMap['unit'].image, width: 30, height: 34),
      );
    }).toList();

    List<DataRow> rows = [];

    if (unitsAfter.isEmpty) {
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  ${unitMap['amount'].toString()}"));
        }).toList()),
      ];
    } else if (attackOutcome == 0 && attackOwned == 1) {
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  -"));
        }).toList()),
        DataRow(cells: List.generate(unitsBefore.length, (index) {
          return DataCell(Text("  -"));
        })),
      ];
    } else {
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  ${unitMap['amount'].toString()}"));
        }).toList()),
        DataRow(cells: List.generate(unitsBefore.length, (index) {
          int before = unitsBefore[index]['amount'];
          int after = unitsAfter[index]['amount'];
          int died = before - after;
          return DataCell(Text("-${died.toString()}"));
        })),
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> decodeUnits(String unitsStr) async {
    if (unitsStr.isEmpty) {
      return [];
    }
    final List decodedList = jsonDecode(unitsStr);

    List<Map<String, dynamic>> sourceUnitsBeforeDecoded = [];
    for (var unitMap in decodedList) {
      int unitId = unitMap['unit_id'];
      var unit = await Unit.getUnitById(unitId);
      sourceUnitsBeforeDecoded.add({
        'unit': unit,
        'amount': unitMap['amount'],
      });
    }
    return sourceUnitsBeforeDecoded;
  }

  Map getEspionageResults(String espionage) {
    Map espionageResults = json.decode(espionage);
    return espionageResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attack Simulator'),
        backgroundColor: Colors.grey,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _sourceVillageIdController,
                decoration: InputDecoration(labelText: 'Source Village ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the source village ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _destinationVillageIdController,
                decoration: InputDecoration(labelText: 'Destination Village ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the destination village ID';
                  }
                  return null;
                },
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildUnitInputField(_sourceUnits, 'Source Units'),
                    _buildUnitInputField(_destinationUnits, 'Destination Units'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _simulateAttack,
                child: Text('Simulate Attack'),
              ),
              Text(_result),
            ],
          ),
        ),
      ),
    );
  }
}
