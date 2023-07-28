class Habit {
  int id;
  String title;
  int reward;
  int monday;
  int tuesday;
  int wednesday;
  int thursday;
  int friday;
  int saturday;
  int sunday;

  String created;
  // Add other properties as per your needs

  // Habit constructor
  Habit({required this.id,
    required this.title,
    required this.reward,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.created
  });

  // Convert a Habit object into a Map
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'reward': reward,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
      'created': created
    };
    map['id'] = id;
    return map;
  }



  // Convert a Map into a Habit object
  Habit.fromMap(Map<String, dynamic> map)
      : id = map['_id'] as int? ?? 0,
        title = map['title'],
        reward = map['reward'],
        monday = map['monday'],
        tuesday = map['tuesday'],
        wednesday = map['wednesday'],
        thursday = map['thursday'],
        friday = map['friday'],
        saturday = map['saturday'],
        sunday = map['sunday'],
        created = map['created'];// Initialize other properties
}
