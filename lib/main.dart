import 'package:flutter/material.dart';
import 'habit.dart';

void main() => runApp(HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamify Life',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HabitList(),
    );
  }
}

class HabitList extends StatefulWidget {
  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  final habits = <Habit>[
  ];

  int coins = 0;


  void _createHabit(BuildContext context) {
    String title = '';
    int reward = 0;
    String? frequency = 'Daily';  // set a default value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(hintText: "Habit Title"),
              ),
              TextField(
                onChanged: (value) {
                  reward = int.parse(value);
                },
                decoration: InputDecoration(hintText: "Reward"),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: frequency,
                onChanged: (String? newValue) {
                  setState(() {
                    frequency = newValue;
                  });
                },
                items: <String>['Daily', 'Weekly', 'Monthly'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  habits.add(Habit(title: title, reward: reward, frequency: "1"));
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editHabit(BuildContext context, int index) {
    String title = habits[index].title;
    int reward = habits[index].reward;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: TextEditingController(text: title),
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(hintText: "Habit Title"),
              ),
              TextField(
                controller: TextEditingController(text: reward.toString()),
                onChanged: (value) {
                  reward = int.parse(value);
                },
                decoration: InputDecoration(hintText: "Reward"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  habits[index] = Habit(title: title, reward: reward);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Tracker'),
        actions: <Widget>[
          ElevatedButton(
            child: Text('Reset Counter'),
            onPressed: () {
              setState(() {
                coins = 0;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(habits[index].title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Reward: ${habits[index].reward} coins'),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      habits.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              // increment coins when habit is done
              setState(() {
                coins += habits[index].reward;
              });
            },
            onLongPress: () => _editHabit(context, index),  // call the _editHabit method here

          );

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createHabit(context),
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            children: <Widget>[
              Text('$coins', style: const TextStyle(fontSize: 50)), // Increase the font size here),
            ],
          ),
        ),
      ),
    );
  }

}
