class Habit {
  Habit({required this.title, this.reward = 0, this.frequency = 'Daily'});

  String title;
  int reward;
  String frequency;  // could also be a custom data type
  DateTime? lastPerformed;
}
