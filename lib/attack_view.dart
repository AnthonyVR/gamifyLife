import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habit/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'models/attack.dart';

class AttackView extends StatefulWidget {
  @override
  _AttackViewState createState() => _AttackViewState();
}

class _AttackViewState extends State<AttackView> {
  late Future<List<Attack>> attacks;

  @override
  void initState() {
    super.initState();
    attacks = Attack.getAllAttacks();
  }


  @override
  Widget build(BuildContext context) {
    String formatTimestamp(String timestamp) {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('d MMMM y, HH:mm:ss').format(dateTime);  // Adjust format as needed
    }
    return Scaffold(
      appBar: AppBar(title: Text("Attacks"), backgroundColor: Colors.grey,),
      body: FutureBuilder<List<Attack>>(
        future: attacks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Error loading attacks"));
            }
            final attackList = snapshot.data!;
            return ListView.builder(
              itemCount: attackList.length,
              itemBuilder: (context, index) {
                final attack = attackList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                  child: Card(
                    elevation: 4.0, // Provides the shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Rounded corners for ListTile
                    ),
                    child: ListTile(
                      tileColor: attack.outcome == 0 ? Colors.red[100] : Colors.green[100],
                      title: Text(formatTimestamp(attack.arrivedAt.toIso8601String())),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From: ${attack.sourceVillageName}"),
                          Text("To: ${attack.destinationVillageName}")
                        ],
                      ),
                      trailing: Image.asset(
                        attack.owned == 1 ? 'assets/attack.png' : 'assets/defense.png',
                        width: 24.0,  // Adjust width as needed
                        height: 24.0, // Adjust height as needed
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _attackDetailsDialog(attack),
                        );
                      },
                    ),
                  ),
                );


              },
            );

          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _attackDetailsDialog(Attack attack) {
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
                Center(child: generateUnitsTable(attack.sourceUnitsBefore, attack.sourceUnitsAfter, 1)),
                SizedBox(height: 30),
                Center(child: Text("Defender: ${attack.destinationVillageName ?? 'Unknown'}")),
                Center(child: generateUnitsTable(attack.destinationUnitsBefore, attack.destinationUnitsAfter, attack.outcome)),
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
                Center(child: Text("Damage: ${attack.damage}")),
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
                        color: _getLuckColor(attack.luck),
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


  Color _getLuckColor(int luck) {
    const double minLuck = -15.0;
    const double maxLuck = 15.0;

    return Color.lerp(
      Colors.red,
      Colors.green,
      (luck.toDouble() - minLuck) / (maxLuck - minLuck),
    )!;
  }



  Widget generateUnitsTable(String unitsBeforeStr, String unitsAfterStr, int attackOutcome) {
    List<Map<String, dynamic>> unitsBefore = decodeUnits(unitsBeforeStr);
    List<Map<String, dynamic>> unitsAfter = decodeUnits(unitsAfterStr);

    // Create columns from the first list, assuming it will always have all units.
    List<DataColumn> columns = unitsBefore.map((unitMap) {
      return DataColumn(
        label: Image.asset(unitMap['unit']['image'], width: 30, height: 34), // adjust width and height as needed
      );
    }).toList();

    List<DataRow> rows = [];

    // Check if attackOutcome == 1
    if (attackOutcome == 1) {
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
    } else {
      rows = [
        DataRow(cells: unitsBefore.map((unitMap) {
          return DataCell(Text("  -"));
        }).toList()),
        DataRow(cells: List.generate(unitsBefore.length, (index) {
          return DataCell(Text("  -"));
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



  List<Map<String, dynamic>> decodeUnits(String unitsStr) {
    final List decodedList = jsonDecode(unitsStr);
    print("decoded list:");
    print(decodedList);
    return List<Map<String, dynamic>>.from(decodedList);
  }


}
