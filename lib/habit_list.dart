import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/habit.dart';
import '/services/database_helper.dart';
import 'habit_editor.dart';


class HabitList extends StatefulWidget {
  const HabitList({super.key});

  @override
  State<HabitList> createState() => HabitListState();
}

class HabitListState extends State<HabitList> {

  List<Habit> habits = [];

  // Add the DatabaseHelper instance
  final dbHelper = DatabaseHelper.instance;


/*  Future<List<Map>> queryTable() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'my_database.db');

    Database db = await openDatabase(path);
    List<Map> result = await db.rawQuery('SELECT * FROM MyTable');
    return result;
  }*/

  void _editHabit(BuildContext context, int index) {
    Habit habit = habits[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {

        return HabitEditor(habit: habit);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Habits'),
      ),

      body: FutureBuilder<List<Habit>>(
        future: dbHelper.getHabits(),
        builder: (BuildContext context, AsyncSnapshot<List<Habit>> snapshot) {
          if (snapshot.hasData) {
            habits = snapshot.data!;
            return ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {

                List<String> activeDays = [];
                if (habits[index].monday == 1) activeDays.add('Monday');
                if (habits[index].tuesday == 1) activeDays.add('Tuesday');
                if (habits[index].wednesday == 1) activeDays.add('Wednesday');
                if (habits[index].thursday == 1) activeDays.add('Thursday');
                if (habits[index].friday == 1) activeDays.add('Friday');
                if (habits[index].saturday == 1) activeDays.add('Saturday');
                if (habits[index].sunday == 1) activeDays.add('Sunday');

                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(habits[index].title),
                      Text('Reward: ${habits[index].reward} coins'),
                      // Display the days fields here
                      Text('${activeDays.join(', ')}'),
                      Text('Created: ${habits[index].created}'),
                      SizedBox(height: 15.0),  // Use SizedBox for a vertical space
                      // ... and so on for other days
                    ],
                  ),
                  onLongPress:  () => _editHabit(context, index),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        dbHelper.delete(habits[index].id);  // delete the habit from the database
                        habits.removeAt(index);  // remove the habit from the list
                      });
                    },
                  ),
                );

              },
            );
          } else if (snapshot.hasError) {
            return Text("An error occurred: ${snapshot.error}");
          }
          // While fetching, show a loading spinner.
          return CircularProgressIndicator();
        },      ),

    );
  }
}
