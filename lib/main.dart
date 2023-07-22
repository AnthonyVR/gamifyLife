import 'package:flutter/material.dart';
import 'package:habit/habit_list.dart';
import 'models/habit.dart';
import '/services/database_helper.dart';
import 'habit_creator.dart';
import 'habit_editor.dart';
import 'package:intl/intl.dart';



/* DB INSPECTEN:
View -> Tool Windows -> App Inspection -> Database inspector!!!
 */

void main() => runApp(HabitTrackerApp());

void checkAndUpdateDayTable() async {

  final dbHelper = DatabaseHelper.instance;

  final currentDate = DateTime.now();
  var formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
  final weekday = DateFormat('EEEE').format(currentDate);
  // Try to retrieve a row from the Day table with the current date
  var row = await dbHelper.queryDay(formattedDate);
  // If the row does not exist, insert it
  if (row.isEmpty) {
    await dbHelper.insertDay({'date': formattedDate, 'weekday': weekday});
  }
}

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    checkAndUpdateDayTable();

    return MaterialApp(
      title: 'Gamify Life',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Habit> habits = [];

  // Add the DatabaseHelper instance
  final dbHelper = DatabaseHelper.instance;

  int coins = 0;
  late DateTime currentDate;

  String formattedDate = DateFormat('EE, d MMMM y').format(DateTime.now());
  String currentDay = DateFormat('EEEE').format(DateTime.now());


  String date = "";
  String weekday = 'saturday';

  Map<String, bool> days = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    formattedDate = DateFormat('EE, d MMMM y').format(currentDate);
    currentDay = DateFormat('EEEE').format(currentDate);
  }



  void _editHabit(BuildContext context, int index) {
    Habit habit = habits[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {

        return HabitEditor(habit: habit);
      },
    );
  }

  void updateDate(DateTime newDate) async {
    setState(() {
      currentDate = newDate;
      formattedDate = DateFormat('EE, d MMMM y').format(newDate);
      currentDay = DateFormat('EEEE').format(newDate);

      date = DateFormat('yyyy-MM-dd').format(newDate);
      weekday = DateFormat('EEEE').format(newDate).toLowerCase();
    });
  }

  Future<void> _goToPreviousDate() async {
    print("test");
    String previousDateString = await dbHelper.getPreviousDate(DateFormat('yyyy-MM-dd').format(currentDate));
    DateTime previousDate = DateFormat('yyyy-MM-dd').parse(previousDateString);
    if (previousDate != currentDate) {
      updateDate(previousDate);
    }
  }

  Future<void> _goToNextDate() async {
    print("test");
    String nextDateString = await dbHelper.getNextDate(DateFormat('yyyy-MM-dd').format(currentDate));
    DateTime nextDate = DateFormat('yyyy-MM-dd').parse(nextDateString);
    if (nextDate != currentDate) {
      updateDate(nextDate);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () async {
                await _goToPreviousDate();
              },
            ),
            Text(formattedDate),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () async {
                await _goToNextDate();
              },
            ),
          ],
        ),
        // actions: <Widget>[
          // ElevatedButton(
          //   child: Text('Reset Counter'),
          //   onPressed: () {
          //     setState(() {
          //       coins = 0;
          //     });
          //   },
          // ),
        //],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              child: Text('Menu'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('All habits'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HabitList()),
                );
              },
            ),
            // Add more ListTiles for other options
          ],
        )
      ),
      body: FutureBuilder<List<Habit>>(
        future: dbHelper.getHabits(),
        builder: (BuildContext context, AsyncSnapshot<List<Habit>> snapshot) {
          if (snapshot.hasData) {

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: dbHelper.getHabitsForToday(date, weekday).asStream(),
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.hasData ? snapshot.data!.length : 0,
                    itemBuilder: (context, index) {
                      bool isCompleted = snapshot.data![index]['completedCount'] >= snapshot.data![index][weekday];
                      return ListTile(
                        title: Text(
                          '${snapshot.data![index]['title']} (${snapshot.data![index]['completedCount']})',
                          style: TextStyle(
                            // Grey out the habit if it is completed
                            color: isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('Reward: ${snapshot.data![index]['reward']} coins'),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  print(snapshot.data![index]['id']);
                                  dbHelper.delete(snapshot.data![index]['id']);
                                  snapshot.data?.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        onTap: isCompleted ? null : () async {
                          // increment coins when habit is done
                          setState(() {
                            coins += 1;//snapshot.data[index]['reward'];
                          });
                          // get the current date in 'yyyy-mm-dd' format
                          //String currentDate = date;  //DateFormat('yyyy-MM-dd').format(DateTime.now());
                          // insert the habit completion into the Habit_History table
                          await DatabaseHelper.instance.insertHabitCompletion({
                            DatabaseHelper.columnHabitID: snapshot.data![index]['_id'],
                            DatabaseHelper.columnDate: date,
                            DatabaseHelper.columnCount: 1,
                          });
                        },
                        onLongPress: () => _editHabit(context, index),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                // By default, show a loading spinner.
                return CircularProgressIndicator();

              },
            );

          } else if (snapshot.hasError) {
            return Text("An error occurred: ${snapshot.error}");
          }

          // While fetching, show a loading spinner.
          return CircularProgressIndicator();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {  // Note the async keyword
          await showDialog(  // Note the await keyword
            context: context,
            builder: (context) {
              return HabitCreator();
            },
          );
          // After the dialog is dismissed, refresh the state
          setState(() {});
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            children: <Widget>[
              Text('$coins', style: const TextStyle(fontSize: 50)),
            ],
          ),
        ),
      ),
    );
  }


}
