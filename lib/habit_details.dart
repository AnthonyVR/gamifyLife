import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/habit.dart';
import '/services/database_helper.dart';
import 'habit_editor.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

class HabitData {
  final String date;
  final int amount;

  HabitData(this.date, this.amount);
}

class HabitDetails extends StatefulWidget {
  final int id;

  const HabitDetails({Key? key, required this.id}) : super(key: key);

  @override
  State<HabitDetails> createState() => HabitDetailsState();
}

class HabitDetailsState extends State<HabitDetails> {
  final dbHelper = DatabaseHelper.instance;

  late List<Map<String, dynamic>> history;

  Habit? habit;

  @override
  void initState() {
    super.initState();
    getHabit();
  }

  getHabit() async {
    habit = await dbHelper.habitDao.getHabitById(widget.id);
    setState(() {}); // Trigger a rebuild
  }

  BarChartData generateChartData(List<Map<String, dynamic>> history) {
    // Define some variables.
    const double barWidth = 5;

    // Map your data to BarChartGroupData objects.
    final List<BarChartGroupData> barGroups = history.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      // Use the 'date' as x-axis label.
      final String date = item['date'].toString();

      // Convert 'amount' to a double and use it as y-axis value.
      final double amount = double.parse(item['amount'].toString());

      // Create and return a BarChartGroupData object.
      return BarChartGroupData(
        x: index, // Set index as x value.
        barRods: [
          BarChartRodData(
            toY: amount, // Replaced 'y' with 'toY'
            width: barWidth,
            color: Colors.blue,
          ),
        ],
        showingTooltipIndicators: [], // Set to an empty list to remove the indicators.
      );
    }).toList();

    // Create and return a BarChartData object.
    return BarChartData(
      barGroups: barGroups,
      // Add labels to x-axis.
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double index, TitleMeta meta) {
              final int i = index.toInt();
              return Text(
                history[i]['date'].toString(),
                style: const TextStyle(color: Colors.black, fontSize: 10),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // Disable top titles to remove the indices at the top.
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value.toString(),
                style: const TextStyle(color: Colors.black, fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(habit?.title ?? 'Invalid habit'),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.habitHistoryDao.getHabitHistoryForChart(widget.id),
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  history = snapshot.data!;
                  return BarChart(generateChartData(history.cast<Map<String, dynamic>>()));
                } else if (snapshot.hasError) {
                  return Text("An error occurred: ${snapshot.error}");
                }
                // While fetching, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.habitHistoryDao.getHabitHistory(widget.id),
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  history = snapshot.data!;
                  print(history);
                  print(history.runtimeType);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 0,
                            columns: <DataColumn>[
                              DataColumn(
                                label: SizedBox(
                                  width: constraints.maxWidth / 3, // allocate half of space to date column
                                  child: Text('Date'),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: constraints.maxWidth / 3, // allocate half of space to amount column
                                  child: Text('Times performed'),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: constraints.maxWidth / 3, // allocate half of space to amount column
                                  child: Text('Earned', textAlign: TextAlign.center),
                                ),
                              ),
                            ],
                            rows: List<DataRow>.generate(
                              history.length,
                                  (int index) => DataRow(
                                cells: <DataCell>[
                                  DataCell(SizedBox(width: constraints.maxWidth / 3, child: Text('${history[index]['date']}'))),
                                  DataCell(SizedBox(width: constraints.maxWidth / 3, child: Text('${history[index]['amount']}', textAlign: TextAlign.center))),
                                  DataCell(
                                    SizedBox(
                                      width: constraints.maxWidth / 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/coins.svg',
                                            height: 20,
                                            width: 20,
                                          ),
                                          Text(' ${history[index]['amount'] * (habit?.difficulty ?? 1)}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("An error occurred: ${snapshot.error}");
                }
                // While fetching, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }
}
