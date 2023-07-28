import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit/habit_list.dart';
import 'package:habit/habit_details.dart';
import 'models/habit.dart';
import '/services/database_helper.dart';
import 'habit_creator.dart';
import 'habit_editor.dart';
import 'package:intl/intl.dart';
import 'config/globals.dart';
import 'models/player.dart';
import 'village.dart';

/* DB INSPECTEN:
View -> Tool Windows -> App Inspection -> Database inspector!!!
 */

void main() => runApp(HabitTrackerApp());

void checkAndUpdateDayTable() async {

  final dbHelper = DatabaseHelper.instance;

  final currentDate = DateTime.now().subtract(const Duration(hours: 8));
  print(currentDate);
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
        fontFamily: 'Tangerine',
        textTheme: const TextTheme(
          bodyText2: TextStyle(fontSize: 20), // replace with desired size
        ),
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

  PlayerModel playerModel = PlayerModel();
  final String appMode = GlobalVariables.appMode; // test | prod

  List<Habit> habits = [];

  // Add the DatabaseHelper instance
  final dbHelper = DatabaseHelper.instance;

  int coins = 0;
  late DateTime currentDate;

  String readableDate = DateFormat('EE, d MMMM y').format(DateTime.now().subtract(const Duration(hours: 8)));
  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(hours: 8)));
  String currentDay = DateFormat('EEEE').format(DateTime.now().subtract(const Duration(hours: 8)));

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

    playerModel.loadPlayer();

    currentDate = DateTime.now().subtract(const Duration(hours: 8));
    readableDate = DateFormat('EE, d MMMM y').format(currentDate);
    currentDay = DateFormat('EEEE').format(currentDate);

    updateDate(currentDate);
    setState(() {

    });
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
      readableDate = DateFormat('EE, d MMMM y').format(newDate);
      currentDay = DateFormat('EEEE').format(newDate);

      date = DateFormat('yyyy-MM-dd').format(newDate);
      weekday = DateFormat('EEEE').format(newDate).toLowerCase();
    });
  }

  Future<void> _goToPreviousDate() async {
    String previousDateString = await dbHelper.getPreviousDate(DateFormat('yyyy-MM-dd').format(currentDate));
    DateTime previousDate = DateFormat('yyyy-MM-dd').parse(previousDateString);
    if (previousDate != currentDate) {
      updateDate(previousDate);
    }
  }

  Future<void> _goToNextDate() async {
    String nextDateString = await dbHelper.getNextDate(DateFormat('yyyy-MM-dd').format(currentDate));
    DateTime nextDate = DateFormat('yyyy-MM-dd').parse(nextDateString);
    if (nextDate != currentDate) {
      updateDate(nextDate);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.lightGreenAccent,
      appBar: AppBar(
        backgroundColor: appMode == 'test' ? Colors.green : Colors.green,
        title: Row(
          children: [
            Expanded(
              flex: 6,  // this will allocate 3 parts of the space to this child
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_left),
                    onPressed: () async {
                      await _goToPreviousDate();
                    },
                  ),
                  Expanded(  // New line
                    child: Text(readableDate),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right),
                    onPressed: () async {
                      await _goToNextDate();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,  // this will allocate 1 part of the space to this child
              child: Align(
                alignment: Alignment.centerRight,
                child: FutureBuilder<int>(
                  future: dbHelper.getTotalRewardsForToday(date, weekday),
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();  // show loading spinner while waiting
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');  // show error message if there's any error
                    } else {
                      return Text('${snapshot.data}');  // display total rewards when data is available
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Add this line
                children: <Widget>[
                  Text('Menu', style: TextStyle(fontSize: 24, color: Colors.white)),
                  Text('Total Score: ${playerModel.player.score}', style: TextStyle(color: Colors.white)),
                  // More children here
                ],
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
            ListTile(
              title: Text('Delete habit history'),
              onTap: () {
                if(appMode == 'test'){
                  dbHelper.removeAllHabitHistory();
                }
                else {
                  print("cannot remove production data");
                }
              },
            ),
            ListTile(
              title: Text('Delete all habits'),
              onTap: () {
                if(appMode == 'test'){
                  dbHelper.removeAllHabits();
                  setState(() {

                  });
                }
                else {
                  print("cannot remove production data");
                }
              },
            ),
            ListTile(
              title: Text('Reset player data'),
              onTap: () {
                if(appMode == 'test'){
                  playerModel.resetData();
                  setState(() {
                  });
                }
                else {
                  print("cannot remove production data");
                }
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
                        title: Row(
                          children: <Widget>[
                            SvgPicture.asset('assets/coin.svg',
                              height: 20,
                              width: 20,),
                            Text(
                              ' ${snapshot.data![index]['reward']}',
                              style: TextStyle(
                                // Grey out the habit if it is completed
                                color: isCompleted ? Colors.grey : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(  // Wrap your Text widget with Expanded
                              child: Text(
                                '${snapshot.data![index]['title']}',
                                style: TextStyle(
                                  color: isCompleted ? Colors.grey : Colors.black,
                                ),
                                softWrap: true,  // Optional: this allows the text to wrap onto the next line
                                //overflow: TextOverflow.ellipsis,  // Optional: this truncates any text that still doesn't fit after wrapping
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.undo_sharp),
                              onPressed: () {
                                setState(() {
                                  playerModel.removeCoins(snapshot.data![index]['reward']);
                                  playerModel.removeScore(snapshot.data![index]['reward']);
                                  dbHelper.undo(snapshot.data![index]['_id'], date);
                                });
                              },
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // places the free space evenly between the children
                            children: <Widget>[
                              Expanded( // Wrap the Row widget with Expanded
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('x${snapshot.data![index]['completedCount']} = '),

                                    SvgPicture.asset(
                                      'assets/coins.svg',
                                      height: 20,
                                      width: 20,
                                    ),
                                    Text(' ${snapshot.data![index]['reward'] * snapshot.data![index]['completedCount']} '),
                                  ],
                                ),
                              ),
                            ],
                        ),

                        onTap: isCompleted ? null : () async {

                          // insert the habit completion into the Habit_History table
                          await DatabaseHelper.instance.insertHabitCompletion({
                            DatabaseHelper.columnHabitID: snapshot.data![index]['_id'],
                            DatabaseHelper.columnDate: date,
                            DatabaseHelper.columnCount: 1,
                          });

                          // update the coins in the player table
                          await playerModel.addCoins(snapshot.data![index]['reward']);
                          await playerModel.addScore(snapshot.data![index]['reward']);

                          setState(() {
                          });

                        },
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HabitDetails(id: snapshot.data![index]['_id'])),
                          );
                        }
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
              return HabitCreator(date: formattedDate);
            },
          );
          // After the dialog is dismissed, refresh the state
          setState(() {});
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // this line is new
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/coins.svg',
                      height: 40,
                      width: 40,),
                    Text(' ${playerModel.player.coins}', style: const TextStyle(fontSize: 25)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Village(),
                            fullscreenDialog: true, // make the page full screen
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/village.png',
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()), // This is to take up the remaining space on the right side.
            ],
          ),
        ),
      ),
    );
  }


}
