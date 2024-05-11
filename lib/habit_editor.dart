import 'package:flutter/material.dart';
import '/services/database_helper.dart';
import 'models/habit.dart';

class HabitEditor extends StatefulWidget {
  final int habitId;

  HabitEditor({Key? key, required this.habitId}) : super(key: key);

  @override
  _HabitEditorState createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  final dbHelper = DatabaseHelper.instance;
  String title = '';
  int difficulty = 0;
  int timesPerDay = 1;
  String created = '';
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
    _loadHabit();
  }

  void _loadHabit() async {
    Habit? habit = await dbHelper.habitDao.getHabitById(widget.habitId);
    print("printing while loading");
    print(habit?.toMap());
    if (habit != null) {
      setState(() {
        title = habit.title;
        difficulty = habit.difficulty;
        created = habit.created;
        days['Monday'] = habit.monday > 0;
        days['Tuesday'] = habit.tuesday > 0;
        days['Wednesday'] = habit.wednesday > 0;
        days['Thursday'] = habit.thursday > 0;
        days['Friday'] = habit.friday > 0;
        days['Saturday'] = habit.saturday > 0;
        days['Sunday'] = habit.sunday > 0;
        timesPerDay = habit.monday; // Assuming same times per day for all days
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: TextEditingController(text: title),
              onChanged: (value) => title = value,
              decoration: InputDecoration(hintText: "Habit Title"),
            ),
            TextField(
              controller: TextEditingController(text: difficulty.toString()),
              onChanged: (value) => difficulty = int.parse(value),
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
                  width: 50,
                  child: TextField(
                    controller: TextEditingController(text: timesPerDay.toString()),
                    onChanged: (value) => timesPerDay = int.tryParse(value) ?? 1,
                    decoration: InputDecoration(),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Text("times per day"),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 85,
                  child: TextFormField(
                    controller: TextEditingController(text: created),
                    onChanged: (value) => created = value,
                    decoration: InputDecoration(),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                SizedBox(width: 10),
                Text("Custom created date"),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () async {
            Map<String, dynamic> row = {
              DatabaseHelper.columnTitle: title,
              DatabaseHelper.columnDifficulty: difficulty,
              DatabaseHelper.columnMonday: days['Monday']! ? timesPerDay : 0,
              DatabaseHelper.columnTuesday: days['Tuesday']! ? timesPerDay : 0,
              DatabaseHelper.columnWednesday: days['Wednesday']! ? timesPerDay : 0,
              DatabaseHelper.columnThursday: days['Thursday']! ? timesPerDay : 0,
              DatabaseHelper.columnFriday: days['Friday']! ? timesPerDay : 0,
              DatabaseHelper.columnSaturday: days['Saturday']! ? timesPerDay : 0,
              DatabaseHelper.columnSunday: days['Sunday']! ? timesPerDay : 0,
              DatabaseHelper.columnCreated: created
            };

            Habit habit = Habit.fromMap(row);
            habit.id = widget.habitId;
            print('habit from row:');
            print(row);
            await habit.updateToDb();
            // await dbHelper.habitDao.update(row);
            // print('Updated habit id: ${widget.habitId}');
            Navigator.of(context).pop();
            setState(() {

            });
          },
        ),
      ],
    );
  }
}
