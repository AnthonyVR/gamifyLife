import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habit/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'models/attack.dart';
import 'models/unit.dart';
import 'main.dart';

class AttackView extends StatefulWidget {
  @override
  _AttackViewState createState() => _AttackViewState();
}

class _AttackViewState extends State<AttackView> {
  List<Attack> outgoingAttacksInTransit = [];
  List<Attack> outgoingAttacksPast = [];

  List<Attack> incomingAttacksInTransit = [];
  List<Attack> incomingAttacksPast = [];


  @override
  void initState() {
    calculateEvents();
    super.initState();

    processAttacks();
  }

  Future<void> processAttacks() async {
    List<Attack> allAttacks = await Attack.getAllAttacks();


    DateTime now = DateTime.now();

    // split by outgoing and incoming
    List<Attack> outgoingAttacks = allAttacks.where((attack) => attack.owned == 1).toList();
    List<Attack> incomingAttacks = allAttacks.where((attack) => attack.owned == 0).toList();


    // outgoing attacks should show 'in transit' when they're on their way to destination or returning
    List<Attack> outgoingAttacksInTransit = outgoingAttacks.where((attack) =>
    attack.completed < 2
    ).toList();
    List<Attack> outgoingAttacksPast = outgoingAttacks.where((attack) =>
    attack.completed == 2
    ).toList();

    // incoming attacks should only show 'in transit' when they're on their way to destination
    List<Attack> incomingAttacksInTransit = incomingAttacks.where((attack) =>
    attack.completed == 0
    ).toList();
    List<Attack> incomingAttacksPast = incomingAttacks.where((attack) =>
    attack.completed > 0
    ).toList();

    // Update the state with the filtered lists
    setState(() {
      this.outgoingAttacksInTransit = outgoingAttacksInTransit;
      this.outgoingAttacksPast = outgoingAttacksPast;
      this.incomingAttacksInTransit = incomingAttacksInTransit;
      this.incomingAttacksPast = incomingAttacksPast;
    });
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,  // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text("Attacks"),
          backgroundColor: Colors.grey,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Incoming Tab
            Column(
              children: [
                SizedBox(height: 10,),
                Text("Incoming"),
                Expanded(
                  child: buildAttackList(incomingAttacksInTransit),
                ),
                Divider(),
                Text("History"),
                Expanded(
                  child: buildAttackList(incomingAttacksPast),
                ),
              ],
            ),
            // Outgoing Tab
            Column(
              children: [
                SizedBox(height: 10,),
                Text("In transit"),
                Expanded(
                  child: buildAttackList(outgoingAttacksInTransit),
                ),
                Divider(),
                Text("History"),
                Expanded(
                  child: buildAttackList(outgoingAttacksPast),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget buildAttackList(List<Attack> attacks) {
    return ListView.builder(
      itemCount: attacks.length,
      itemBuilder: (context, index) {
        final attack = attacks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
              child: ListTile(
                tileColor: attack.opened == 1
                    ? attack.arrivedAt.isAfter(DateTime.now())
                    ? Colors.white.withOpacity(0.5) // Faded white
                    : (attack.outcome == 0 ? Colors.pink[100]!.withOpacity(0.4) : Colors.lightGreen[100]!.withOpacity(0.4))
                    : attack.arrivedAt.isAfter(DateTime.now())
                    ? Colors.white
                    : (attack.outcome == 0 ? Colors.red[500] : Colors.green[500]),
                title: attack.arrivedAt.isAfter(DateTime.now())
                    ? (attack.returnedAt == null
                    ? Text(" Arrival: ${DateFormat('d MMMM y, HH:mm:ss').format(attack.arrivedAt)}")
                    : Text(" Arrival: ${DateFormat('d MMMM y, HH:mm:ss').format(attack.arrivedAt)} \n(Return: ${DateFormat('d MMMM y, HH:mm:ss').format(attack.returnedAt!)} )"))
                    : (attack.returnedAt == null
                    ? Text(" Return: Not available")
                    : Text(" Return: ${DateFormat('d MMMM y, HH:mm:ss').format(attack.returnedAt!)}")),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(" From: ${attack.sourceVillageName}"),
                    Text(" To: ${attack.destinationVillageName}")
                  ],
                ),
                trailing: Image.asset(
                  attack.owned == 1 ? 'assets/attack.png' : 'assets/defense.png',
                  width: 24.0,
                  height: 24.0,
                ),
                onTap: () {
                  if (attack.completed > 0) {
                    showDialog(
                      context: context,
                      builder: (context) => _attackDetailsDialog(attack),
                    );
                  } else if(attack.owned == 1) {
                    showDialog(
                      context: context,
                      builder: (context) => _showOutgoingAttackDetails(attack),
                    );
                  }
                },
              ),
          ),
        );
      },
    );
  }

  Map getEspionageResults(String espionage){

    Map espionageResults = json.decode(espionage);
    return espionageResults;
  }


  Widget _attackDetailsDialog(Attack attack) {
    String formatTimestamp(String timestamp) {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('d MMMM y, HH:mm:ss').format(dateTime);  // Adjust format as needed
    }

    if(attack.opened == 0){
      attack.opened = 1;
      attack.updateToDb();
    }

    return Dialog(
      insetPadding: EdgeInsets.all(10.0), // make dialog almost full screen
      child: Container(
        decoration: BoxDecoration(
          color: attack.outcome == 0 ? Colors.red[100] : Colors.green[100],
          boxShadow: attack.opened == 1 ? [
            BoxShadow( // Shadow effect if viewed
              color: Colors.green.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ] : null,
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
                Center(child: Text("Returned: ${formatTimestamp(attack.returnedAt!.toIso8601String())}")),
                SizedBox(height: 50),
                Center(child: Text("Attacker: ${attack.sourceVillageName ?? 'Unknown'}")),

                FutureBuilder<Widget>(
                  future: generateUnitsTable(attack.sourceUnitsBefore, attack.sourceUnitsAfter!, 1, attack.owned),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();  // return a loader while waiting
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(child: snapshot.data!);  // return the actual widget once the future is complete
                    }
                  },
                ),
                SizedBox(height: 30),
                Center(child: Text("Defender: ${attack.destinationVillageName ?? 'Unknown'}")),
                FutureBuilder<Widget>(
                  future: generateUnitsTable(attack.destinationUnitsBefore!, attack.destinationUnitsAfter!, attack.outcome!, attack.owned),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();  // return a loader while waiting
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(child: snapshot.data!);  // return the actual widget once the future is complete
                    }
                  },
                ),
                SizedBox(height: 30.0),  // You can adjust the spacing as needed
                Center(child: Text("Loot:")),
                SizedBox(height: 5.0),  // You can adjust the spacing as needed
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,  // This will center the contents of the Row
                    children: [
                      SvgPicture.asset(
                        'assets/coins.svg',
                        width: 26,
                        height: 26,
                      ),
                      SizedBox(width: 5.0),
                      Text('${attack.loot}',
                      style: const TextStyle(fontSize: 28)),
                    ],
                  ),
                ),
                SizedBox(height: 30.0),  // You can adjust the spacing as needed
                Center(child: Text("Damage to townhall: ${attack.damage}")),
                SizedBox(height: 30.0),  // You can adjust the spacing as needed
                attack.espionage != null? Center(child: Text(
                    "Espionage: \n Coins: ${getEspionageResults(attack.espionage!)['coins']} "
                        "\n Townhall: ${getEspionageResults(attack.espionage!)['townhall']} "
                        "\n Barracks: ${getEspionageResults(attack.espionage!)['barracks']} "
                        "\n Farm: ${getEspionageResults(attack.espionage!)['farm']}")) : SizedBox(width: 5.0),
              ],
            ),
            Positioned(
              top: 10.0,
              right: 10.0,
              child: Stack(
                alignment: Alignment.center, // Center the text over the image
                children: [
                  // The luck image
                  Image.asset('assets/luck.png', width: 50.0, height: 50.0,),  // Adjust width and height as desired

                  // The luck text
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
              child: Image.asset(attack.owned == 1 ? 'assets/attack.png' : 'assets/defense.png', width: 40.0, height: 40.0,),  // Adjust width and height as needed
            ),
          ],
        ),
      ),
    );
  }

  Widget _showOutgoingAttackDetails(Attack attack) {
    String formatTimestamp(String timestamp) {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('d MMMM y, HH:mm:ss').format(dateTime);  // Adjust format as needed
    }


    return Dialog(
      insetPadding: EdgeInsets.all(10.0), // make dialog almost full screen
      child: Container(
        decoration: BoxDecoration(
          color: attack.outcome == 0 ? Colors.red[100] : Colors.green[100],
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(8.0),
              children: [
                Center(child: Text(formatTimestamp(attack.arrivedAt.toIso8601String()))),
                SizedBox(height: 80),
                Center(child: Text("Attacker: ${attack.sourceVillageName ?? 'Unknown'}")),
                FutureBuilder<Widget>(
                  future: generateUnitsTable(attack.sourceUnitsBefore, "", 1, attack.owned),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();  // return a loader while waiting
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Center(child: snapshot.data!);  // return the actual widget once the future is complete
                    }
                  },
                ),
              ],
            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              child: Image.asset(attack.owned == 1 ? 'assets/attack.png' : 'assets/defense.png', width: 40.0, height: 40.0,),  // Adjust width and height as needed
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
      return Center(child: Text('\n- No defending units - ', style: TextStyle(fontStyle: FontStyle.italic),));
    }
    // Create columns from the first list, assuming it will always have all units.
    List<DataColumn> columns = unitsBefore.map((unitMap) {
      return DataColumn(
        label: Image.asset(unitMap['unit'].image, width: 30, height: 34), // adjust width and height as needed
      );
    }).toList();

    List<DataRow> rows = [];

    // if it's an outgoing attack show only the attacking units
    if (unitsAfter.isEmpty) {
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  ${unitMap['amount'].toString()}"));
        }).toList()),
      ];

    }


    else if (attackOutcome == 0 && attackOwned == 1){
      print('OPTION 2');
      print(attackOutcome);
      print(attackOwned);
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  -"));
        }).toList()),
        DataRow(cells: List.generate(unitsBefore.length, (index) {
          return DataCell(Text("  -"));
        })),
      ];
    } else{
      print('OPTION 1');
      print(attackOutcome);
      print(attackOwned);
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

    // Check if attackOutcome == 1
    // else if (attackOutcome == 1 || attackOwned == 0) {
    //   print('OPTION 1');
    //   print(attackOutcome);
    //   print(attackOwned);
    //   rows = [
    //     DataRow(cells: unitsBefore.map((unitMap) {
    //       return DataCell(Text("  ${unitMap['amount'].toString()}"));
    //     }).toList()),
    //     DataRow(cells: List.generate(unitsBefore.length, (index) {
    //       int before = unitsBefore[index]['amount'];
    //       int after = unitsAfter[index]['amount'];
    //       int died = before - after;
    //       return DataCell(Text("-${died.toString()}"));
    //     })),
    //   ];
    // } else {
    //   print('OPTION 2');
    //   print(attackOutcome);
    //   print(attackOwned);
    //   rows = [
    //     DataRow(cells: unitsBefore.map((unitMap) {
    //       return DataCell(Text("  -"));
    //     }).toList()),
    //     DataRow(cells: List.generate(unitsBefore.length, (index) {
    //       return DataCell(Text("  -"));
    //     })),
    //   ];
    // }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
      ),
    );
  }


  Future<List<Map<String, dynamic>>> decodeUnits(String unitsStr) async {
    if(unitsStr.isEmpty){
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


}
