import 'package:flutter/material.dart';
import '/services/database_helper.dart';

class HabitCreator extends StatefulWidget {
  final String date;

  HabitCreator({Key? key, required this.date}) : super(key: key);

  @override
  _HabitCreatorState createState() => _HabitCreatorState();
}

class _HabitCreatorState extends State<HabitCreator> {
  final dbHelper = DatabaseHelper.instance;
  String title = '';
  int difficulty = 0;
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
    String created = widget.date;

    print(created);


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
                difficulty = int.parse(value);
              },
              decoration: InputDecoration(hintText: "Difficulty"),
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
            Row(
              children: <Widget>[
                Container(
                  width: 85, // You can adjust the width as needed
                  child: TextFormField(
                    initialValue: created,
                    onChanged: (value) {
                      created = value; // assign the input value to 'created'
                    },
                    decoration: InputDecoration(),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                SizedBox(width: 10), // for a little bit of spacing
                Text("Custom created date"),
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
              DatabaseHelper.columnDifficulty: difficulty,
              //DatabaseHelper.columnTimesPerDay: timesPerDay, // add this line
              DatabaseHelper.columnMonday: days['Monday']! ? timesPerDay : 0,
              DatabaseHelper.columnTuesday: days['Tuesday']! ? timesPerDay : 0,
              DatabaseHelper.columnWednesday: days['Wednesday']! ? timesPerDay : 0,
              DatabaseHelper.columnThursday: days['Thursday']! ? timesPerDay : 0,
              DatabaseHelper.columnFriday: days['Friday']! ? timesPerDay : 0,
              DatabaseHelper.columnSaturday: days['Saturday']! ? timesPerDay : 0,
              DatabaseHelper.columnSunday: days['Sunday']! ? timesPerDay : 0,
              DatabaseHelper.columnCreated: created
            };
            int id = await dbHelper.habitDao.insert(row);  // insert the habit
            print('inserted row id: $id');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

}
