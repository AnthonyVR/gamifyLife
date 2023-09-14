import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import 'models/habit.dart'; // Assuming your Habit model is located here

class HabitEditor extends StatefulWidget {
  final Habit habit;

  const HabitEditor({Key? key, required this.habit}) : super(key: key);

  @override
  _HabitEditorState createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final dbHelper = DatabaseHelper.instance;
  late String title;
  late int reward;
  late Map<String, bool> days;

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields with the current data of the habit
    title = widget.habit.title;
    reward = widget.habit.reward;
    days = {
      'Monday': widget.habit.monday == 1,
      'Tuesday': widget.habit.tuesday == 1,
      'Wednesday': widget.habit.wednesday == 1,
      'Thursday': widget.habit.thursday == 1,
      'Friday': widget.habit.friday == 1,
      'Saturday': widget.habit.saturday == 1,
      'Sunday': widget.habit.sunday == 1,
    };
  }

  @override
  Widget build(BuildContext context) {
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
          // Add a CheckboxListTile for each day of the week
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
          onPressed: () async {
            Map<String, dynamic> row = {
              DatabaseHelper.columnId: widget.habit.id,
              DatabaseHelper.columnTitle: title,
              DatabaseHelper.columnReward: reward,
              DatabaseHelper.columnMonday: days['Monday']! ? 1 : 0,
              DatabaseHelper.columnTuesday: days['Tuesday']! ? 1 : 0,
              DatabaseHelper.columnWednesday: days['Wednesday']! ? 1 : 0,
              DatabaseHelper.columnThursday: days['Thursday']! ? 1 : 0,
              DatabaseHelper.columnFriday: days['Friday']! ? 1 : 0,
              DatabaseHelper.columnSaturday: days['Saturday']! ? 1 : 0,
              DatabaseHelper.columnSunday: days['Sunday']! ? 1 : 0,
            };
            int id = await dbHelper.habitDao.update(row);  // update the habit
            print('updated row id: $id');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
