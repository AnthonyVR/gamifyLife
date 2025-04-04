import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:workmanager/workmanager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habit/attack_simulator.dart';
import 'package:habit/event_view.dart';
import 'package:habit/habit_list.dart';
import 'package:habit/habit_details.dart';
import 'package:habit/models/attack.dart';
import 'package:habit/settings_view.dart';
import 'package:habit/village_view.dart';
import 'attack_view.dart';
import 'database_view.dart';
import 'models/event.dart';
import 'models/habit.dart';
import '/services/database_helper.dart';
import 'habit_creator.dart';
import 'habit_editor.dart';
import 'package:intl/intl.dart';
import 'config/globals.dart';
import 'models/player.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'map_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/unit.dart';
import 'models/village.dart';

/* DB INSPECTEN:
View -> Tool Windows -> App Inspection -> Database inspector!!!
 */

// @pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
// void callbackDispatcher() {
//
//   print("RUNNING callbackDispatcher");
//
//   Workmanager().executeTask((task, inputData) async{
//     print("Background task: $task"); // task name is useful for debugging
//
//     final db = await DatabaseHelper.instance.database;
//
//     print("obtained DB object");
//
//     if (task == 'calculateEventsTask') {
//       print("TASK ==  calculateEventsTask");
//       calculateEvents(db); // Your function to perform background tasks
//     }
//
//     return Future.value(true); // return true from the callback, indicating the task is successful.
//   });
// }

Future<void> calculateEvents() async {

  try {

    // Add game_opened entry
    Event gameOpened = Event(eventType: 'game_opened', timestamp: DateTime.now(), info: {});

    await Attack.handlePendingAttacks();
    var eventsOccurred = await gameOpened.calculateEvents();
    //await gameOpened.insertToDb(); // Ensure this is awaited if it's async


  } catch (e) {
    print('Error handling background task: $e');
    print("ERROR CALCULATEEVENTS");

    // Consider logging this error to a server or local database if critical
  }
}


void main() async{

  WidgetsFlutterBinding.ensureInitialized();


  // await Workmanager().initialize(
  //     callbackDispatcher, // The top-level function defined above
  //     isInDebugMode: true // Set to false in production
  // );
  // print("workmanager initialized");
  //
  // Workmanager().registerOneOffTask("task-identifier", "simpleTask");
  // print("workmanager onOfftask registered");
  //
  // Workmanager().registerPeriodicTask(
  //   "1", // unique task id
  //   "calculateEventsTask", // task name
  //   frequency: Duration(minutes: 15), // frequency of task execution
  // );
  // print("workmanager periodictask registered");

  // Initialize FFI
  sqfliteFfiInit();

  runApp(HabitTrackerApp());
}

void checkAndUpdateDayTable() async {

  print("running checkAndUpdateDayTable()");
  final dbHelper = DatabaseHelper.instance;

  final currentDate = DateTime.now().subtract(const Duration(hours: 8)); //hours: 8
  print("current date: ${currentDate}");
  var formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
  final weekday = DateFormat('EEEE').format(currentDate);
  // Try to retrieve a row from the Day table with the current date
  var row = await dbHelper.dayDao.queryDay(formattedDate);
  // If the row does not exist, insert it
  if (row.isEmpty) {
    print("inserting new row");
    await dbHelper.dayDao.insertDay({'date': formattedDate, 'weekday': weekday});
    Event.checkTownHallLevelsUps();
  }
}

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Gamify Life',
      theme: ThemeData(
        fontFamily: 'Tangerine',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 20), // replace with desired size
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

  int eventsOccurred = 0;

  void getPlayer() async {
    await playerModel.loadPlayer();
    setState(() {

    });
  }
  // // Called when the application starts
  // Future<void> calculateEvents() async {
  //   // add game_opened entry
  //   Event gameOpened = Event(eventType: 'game_opened', timestamp: DateTime.now(), info: {});
  //   await Attack.handlePendingAttacks();
  //   eventsOccurred = await gameOpened.calculateEvents();
  //   gameOpened.insertToDb();
  //
  //   setState(() {
  //   });
  // }

  void printDbPath() async {
    var databasesPath = await getDatabasesPath();
    print(databasesPath);
  }

  @override
  void initState() {

    super.initState();

    getPlayer();

    print("teeeeeeeeest");
    print(playerModel.player.totalCoinsEarned);

    checkAndUpdateDayTable();

    printDbPath();

    //calculateEvents();

    currentDate = DateTime.now().subtract(const Duration(hours: 8));
    readableDate = DateFormat('EE, d MMMM y').format(currentDate);
    currentDay = DateFormat('EEEE').format(currentDate);

    updateDate(currentDate);
    setState(() {

    });
  }

  // void _editHabit(BuildContext context, int index) {
  //   Habit habit = habits[index];
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //
  //       return HabitEditor(habit: habit);
  //     },
  //   );
  // }


  executeHabit(Map<String, dynamic> habit) async{

    await DatabaseHelper.instance.habitHistoryDao.insertHabitCompletion({
      DatabaseHelper.columnHabitID: habit['id'],
      DatabaseHelper.columnDate: date,
      DatabaseHelper.columnCount: 1,
    });
    //await playerModel.addScore(habit['difficulty']);
    await Village.divideCoins(habit['difficulty']);
    setState(() {});

  }

  undoHabit(Map<String, dynamic> habit) async{
    //await playerModel.removeScore(habit['difficulty']);
    await dbHelper.habitHistoryDao.undo(habit['id'], date);
    await Village.divideCoins(-habit['difficulty']);
    setState(() {});
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
    print('running gotopreviousdate');
    print(currentDate);
    String previousDateString = await dbHelper.dayDao.getPreviousDate(DateFormat('yyyy-MM-dd').format(currentDate));

    print(previousDateString);
    DateTime previousDate = DateFormat('yyyy-MM-dd').parse(previousDateString);
    print(previousDate);
    if (previousDate != currentDate) {
      print("updating date");
      updateDate(previousDate);
    }
  }

  Future<void> _goToNextDate() async {
    String nextDateString = await dbHelper.dayDao.getNextDate(DateFormat('yyyy-MM-dd').format(currentDate));
    DateTime nextDate = DateFormat('yyyy-MM-dd').parse(nextDateString);
    if (nextDate != currentDate) {
      updateDate(nextDate);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // choose here full color package of main screen
      backgroundColor: Colors.black, //Color(0xFFb87a3d),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Default FAB location
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor: GlobalVariables.appMode == 'test' ? Colors.red : Colors.white24,
          title: Row(
            children: [
              Expanded(
                flex: 8,  // this will allocate 3 parts of the space to this child
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: Colors.white60,),
                      onPressed: () async {
                        await _goToPreviousDate();
                      },
                    ),
                    Expanded(  // New line
                      child: Text(readableDate,
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white),),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: Colors.white60,),
                      onPressed: () async {
                        await _goToNextDate();
                      },
                    ),
                    SizedBox(width: 50)
                    // IconButton(
                    //   icon: Icon(Icons.access_alarm),
                    //   onPressed: () async {
                    //     print("running calculateEvents() from alarm button");
                    //     await calculateEvents();
                    //   },
                    // ),
                  ],
                ),
              ),
              // Expanded(
              //   flex: 2,  // this will allocate 1 part of the space to this child
              //   child: Align(
              //     alignment: Alignment.centerRight,
              //     child: FutureBuilder<double>(
              //       future: Village.getTotalRewardFactor(),
              //       builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
              //         if (snapshot.connectionState == ConnectionState.waiting) {
              //           return CircularProgressIndicator();  // show loading spinner while waiting
              //         } else if (snapshot.hasError) {
              //           return Text('Error: ${snapshot.error}');  // show error message if there's any error
              //         } else {
              //           return Text('${snapshot.data}');  // display total difficultys when data is available
              //         }
              //       },
              //     ),
              //   ),
              // ),
              // Expanded(
              //   flex: 2,  // this will allocate 1 part of the space to this child
              //   child: Align(
              //     alignment: Alignment.centerRight,
              //     child: FutureBuilder<int>(
              //       future: dbHelper.habitHistoryDao.getTotalDifficultysForToday(date, weekday),
              //       builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              //         if (snapshot.connectionState == ConnectionState.waiting) {
              //           return CircularProgressIndicator();  // show loading spinner while waiting
              //         } else if (snapshot.hasError) {
              //           return Text('Error: ${snapshot.error}');  // show error message if there's any error
              //         } else {
              //           return Text('${snapshot.data}');  // display total difficultys when data is available
              //         }
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Add this line
                children: <Widget>[
                  Text('Menu', style: TextStyle(fontSize: 24, color: Colors.white)),
                  Text('Total Score: ${playerModel.player.score}', style: TextStyle(color: Colors.white)),
                  Text('Total Coins earned: ${playerModel.player.totalCoinsEarned}', style: TextStyle(color: Colors.white)),
                  // More children here
                ],
              ),
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsView()),
                );
              },
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
              title: Text('Database'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DatabaseView()),
                );
              },
            ),
            // ListTile(
            //   title: Text('Restore database to last version (NOT WORKING)'),
            //   onTap: () async {
            //     try {
            //       await DatabaseHelper.instance.restoreDatabaseFromBackup(DateTime.now().toString());
            //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            //         content: Text("Database restored successfully."),
            //       ));
            //     } catch (e) {
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //         content: Text("Failed to restore database: $e"),
            //       ));
            //     }
            //   },
            // ),
            ListTile(
              title: Text("_Simulator"),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttackSimulator(),
                    fullscreenDialog: true, // make the page full screen
                  ),
                );
              },
            ),
            ListTile(
              title: Text("Backup database"),
              onTap: () async {
                DateTime currentTime = DateTime.now();
                await (DatabaseHelper.instance.backupDatabase(currentTime));
              },
            ),
            ListTile(
              title: Text("Temp"),
              onTap: () async {
                Village village = await Village.getVillageById(2);
                final db = await DatabaseHelper.instance.database;
                village.upgradeBuildingLevel(db, "town_hall", 0);
              },
            ),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Remove AND Rebuild ALL initial database contents'),
              onTap: () {
                dbHelper.clearAndRebuildDatabase();
                setState(() {});
              },
            ) : SizedBox(),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Remove AND Rebuild everything except habits and settings'),
              onTap: () {
                dbHelper.clearAndRebuildDatabaseExceptHabits();
                setState(() {});
              },
            ) : SizedBox(),
            GlobalVariables.appMode == 'test' || true ? ListTile(
              title: Text('Update day table'),
              onTap: () {
                checkAndUpdateDayTable();
                setState(() {});
              },
            ) : SizedBox(),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Trigger incoming attack'),
              onTap: () async {

                Village village = await Village.getVillageById(3);
                List<Unit> enemySourceUnitsList = await village.getAvailableUnits();

                if(enemySourceUnitsList.isNotEmpty){

                    List<Map<String, dynamic>> enemySourceUnits = enemySourceUnitsList.map((unit) {
                      return {
                        'unit': unit,
                        'amount': unit.amount,
                      };
                    }).toList();
                    Attack.createAttack(DateTime.now(), 3, 1, enemySourceUnits);
                  }
                  setState(() {
                  });
                }
            ) : SizedBox(),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Delete habit history'),
              onTap: () {
                dbHelper.habitHistoryDao.removeAllHabitHistory();
                setState(() {
                });
              },
            ): SizedBox(),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Delete all habits'),
              onTap: () {
                dbHelper.habitDao.removeAllHabits();
                setState(() {
                });
              },
            ): SizedBox(),
            GlobalVariables.appMode == 'test' ? ListTile(
              title: Text('Run simulation'),
              onTap: () {
                Village.runSimulation();
                setState(() {
                });
              },
            ): SizedBox(),
            // ListTile(
            //   title: Text('Reset player data'),
            //   onTap: () {
            //     if(GlobalVariables.appMode == 'test' || 1 == 1){
            //       playerModel.resetData();
            //       setState(() {
            //       });
            //     }
            //     else {
            //       print("cannot remove production data");
            //     }
            //   },
            // ),
            ListTile(
              title: Text('App mode: ${GlobalVariables.appMode}'),
              onTap: () async {
                if (GlobalVariables.appMode == 'test' || GlobalVariables.appMode == 'prod') {
                  // Toggle the mode
                  GlobalVariables.appMode = (GlobalVariables.appMode == 'test') ? 'prod' : 'test';
                  print('Switching mode to: ${GlobalVariables.appMode}');

                  // Reinitialize the database with the new mode
                  await DatabaseHelper.instance.initDatabase();

                  // Use setState to rebuild the widget with the new state
                  setState(() {});
                } else {
                  print("Invalid app mode");
                }
              },
            ),
          ],
        )
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          calculateEvents();
          setState(() {
          });
        },
        child: FutureBuilder<List<Habit>>(
          future: dbHelper.habitDao.getHabits(),
          builder: (BuildContext context, AsyncSnapshot<List<Habit>> snapshot) {

            if (snapshot.hasData) {

              return GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (details.primaryVelocity! > 0) {
                    // User swiped Right
                    _goToPreviousDate();
                  } else if (details.primaryVelocity! < 0) {
                    // User swiped Left
                    _goToNextDate();
                  }
                  setState(() {});
                },
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: dbHelper.habitHistoryDao.getHabitsForToday(date, weekday).asStream(),
                  builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {

                    if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: snapshot.hasData ? snapshot.data!.length + 1 : 0,  // Increment the itemCount by 1
                        itemBuilder: (context, index) {
                          if (index == snapshot.data!.length) {  // Check if the index corresponds to the last item
                            // Return an empty ListTile or any other widget you want to appear as the last item
                            return ListTile();
                          }

                          // Existing code for other items
                          bool isCompleted = snapshot.data![index]['completedCount'] >= snapshot.data![index][weekday];
                          double completedPercentage = snapshot.data![index]['completedCount'] / snapshot.data![index][weekday] * 10;
                          int difficulty = snapshot.data![index]['difficulty'];

                          return ListTile(
                              title: Row(
                                children: <Widget>[
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: getDifficultyColor(difficulty),
                                        width: isCompleted ? 10 : completedPercentage, // Adjust the border width
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 40, // Width for the Text widget
                                    child: Text(' ${snapshot.data![index]['completedCount']}x',
                                        style: TextStyle(fontSize: 24, color: isCompleted ? Colors.grey : Colors.white)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      child: Text(
                                        '${snapshot.data![index]['title']}',
                                        style: TextStyle(
                                          color: isCompleted ? Colors.grey : Colors.white,
                                          fontSize: 18,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30, // Width for IconButton
                                    child: IconButton(
                                      icon: Icon(Icons.undo_outlined, color: isCompleted ? Colors.grey : Colors.white, size: 20),
                                      onPressed: () async {
                                        completedPercentage != 0 ? await undoHabit(snapshot.data![index]) : print("nothing");
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Container(
                                          width: 40, // Width for Text
                                          child: Text(
                                            ' $difficulty',
                                            style: TextStyle(
                                              color: isCompleted ? Colors.grey : Colors.yellow,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 20, // Width for SVG
                                          child: SvgPicture.asset(
                                            'assets/coins.svg',
                                            height: 20,
                                            width: 20,
                                          ),
                                        ),
                                        Container(
                                          width: 28, // Width for Text
                                          child: Text(
                                              ' ${snapshot.data![index]['difficulty'] * snapshot.data![index]['completedCount']} ',
                                              style: TextStyle(fontSize: 24, color: isCompleted ? Colors.grey : Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: isCompleted ? null : () async {
                                await executeHabit(snapshot.data![index]);
                              },
                              onLongPress: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => HabitDetails(id: snapshot.data![index]['id'])),
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
                ),
              );

            } else if (snapshot.hasError) {
              return Text("An error occurred: ${snapshot.error}");
            }

            // While fetching, show a loading spinner.
            return CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            right: 20,
            bottom: 90,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () async {
                await showDialog(
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
          ),
          Positioned(
            left: 0,
            bottom: 80,
            child: Container(
              width: 160,  // Define the width of the button
              height: 48,  // Define the height of the button
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Align(
                          alignment: Alignment.topCenter,
                          child: FutureBuilder<int>(
                            future: Village.getTotalRewardFactor(),
                            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                return Text('${snapshot.data}');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),  // Rounded corners
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,  // Use the minimal space for the row content
                  children: [
                    SvgPicture.asset(
                      'assets/coins.svg',
                      height: 20,
                      width: 20,
                    ),
                    SizedBox(width: 6),  // Space between the icon and text
                    FutureBuilder<int>(
                      future: dbHelper.habitHistoryDao.getTotalDifficultysForToday(date, weekday),
                      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();  // Show loading spinner while waiting
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white));  // Show error message if there's any error
                        } else {
                          return Text(
                            '${snapshot.data}',  // Display your data
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,  // Set the font size
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(width: 10),  // Space between the icon and text
                    FutureBuilder<int>(
                      future: Village.getTotalRewardFactor(),
                      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text(
                            'x   ${snapshot.data}',  // Display your data
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 24,  // Set the font size
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white10,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // this line is new
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        //calculateEvents();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventView(),
                            fullscreenDialog: true, // make the page full screen
                          ),
                        );
                      },
                      child: Container(  // <-- Wrap Stack with a Container
                        margin: EdgeInsets.all(8),  // <-- Add margin around Stack
                        child: Stack(
                          clipBehavior: Clip.none,  // <-- Allow for overflow outside the Stack
                          children: <Widget>[
                            // The icon itself
                            Image.asset(
                              'assets/event_log.png',
                              height: 45,
                              width: 45,
                            ),

                            // The number displayed on top of it
                            Positioned(
                              top: -18,  // <-- Now you can use negative values
                              right: -10,  // <-- Now you can use negative values
                              child: Container(
                                padding: EdgeInsets.all(6),  // Adjust the padding as needed
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$eventsOccurred', // your variable here
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,  // Adjust font size as needed
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await calculateEvents();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttackView(),
                            fullscreenDialog: true, // make the page full screen
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/attack.png',
                        height: 45,
                        width: 45,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await calculateEvents();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VillageView(villageId: 1),
                            fullscreenDialog: true, // make the page full screen
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/village_walled.png',
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await calculateEvents();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapView(),
                            fullscreenDialog: true, // make the page full screen
                          ),
                        ); 
                      },
                      child: Image.asset(
                        'assets/map.png',
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getDifficultyColor(int difficulty) {
    if (difficulty >= 1 && difficulty <= 3) {
      return Colors.green;
    } else if (difficulty >= 4 && difficulty <= 7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

}
