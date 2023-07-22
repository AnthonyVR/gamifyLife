import 'package:flutter/material.dart';
import '/services/database_helper.dart';

class HabitCreator extends StatefulWidget {
  HabitCreator({Key? key}) : super(key: key);

  @override
  _HabitCreatorState createState() => _HabitCreatorState();
}

class _HabitCreatorState extends State<HabitCreator> {
  final dbHelper = DatabaseHelper.instance;
  String title = '';
  int reward = 0;
  bool unlimited = false;

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
  Widget build(BuildContext context) {
    int timesPerDay = 1; // default value

    return AlertDialog(
      title: Text('Create Habit'),
      content: SingleChildScrollView(
        child: Column(
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
            ...days.keys.map((day) {
              return CheckboxListTile(
                title: Text(day),
                value: days[day],
                onChanged: (bool? value) {
                  setState(() {
                    days[day] = value!;
                  });
                },
              );
            }).toList(),
            Row(
              children: <Widget>[
                Container(
                  width: 50, // You can adjust the width as needed
                  child: TextField(
                    onChanged: (value) {
                      timesPerDay = int.tryParse(value) ?? 1; // use the entered value, if it's not a number, use 1
                    },
                    decoration: InputDecoration(),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10), // for a little bit of spacing
                Text("times per day"),
              ],
            ),
          ],
        ),
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
          onPressed: () async {
            Map<String, dynamic> row = {
              DatabaseHelper.columnTitle: title,
              DatabaseHelper.columnReward: reward,
              //DatabaseHelper.columnTimesPerDay: timesPerDay, // add this line
              DatabaseHelper.columnMonday: days['Monday']! ? timesPerDay : 0,
              DatabaseHelper.columnTuesday: days['Tuesday']! ? timesPerDay : 0,
              DatabaseHelper.columnWednesday: days['Wednesday']! ? timesPerDay : 0,
              DatabaseHelper.columnThursday: days['Thursday']! ? timesPerDay : 0,
              DatabaseHelper.columnFriday: days['Friday']! ? timesPerDay : 0,
              DatabaseHelper.columnSaturday: days['Saturday']! ? timesPerDay : 0,
              DatabaseHelper.columnSunday: days['Sunday']! ? timesPerDay : 0,
            };
            int id = await dbHelper.insert(row);  // insert the habit
            print('inserted row id: $id');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

}
