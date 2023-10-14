import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habit/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'models/attack.dart';
import 'models/event.dart';

class EventView extends StatefulWidget {
  @override
  _EventViewState createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  late Future<List<Event>> events;

  @override
  void initState() {
    super.initState();
    events = Event.getAllEvents();
  }


  @override
  Widget build(BuildContext context) {
    String formatTimestamp(String timestamp) {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('d MMMM y, HH:mm:ss').format(dateTime);  // Adjust format as needed
    }
    return Scaffold(
      appBar: AppBar(title: Text("Events"), backgroundColor: Colors.grey,),
      body: FutureBuilder<List<Event>>(
        future: events,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Error loading events"));
            }
            final eventList = snapshot.data!;
            return ListView.builder(
              itemCount: eventList.length,
              itemBuilder: (context, index) {
                final event = eventList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                  child: ListTile(
                    tileColor: _getColorForEventType(event.eventType),
                    title: Text(formatTimestamp(event.timestamp.toIso8601String())),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(event.info.toString()),
                            Spacer(), // This will take up all available space between the text widgets
                            Text(event.eventType),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );

          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Color _getColorForEventType(String eventType) {
    switch(eventType) {
      case 'village_spawn':
        return Colors.blue;
      case 'attack': // replace with your actual event type
        return Colors.red; // replace with the desired color
      case 'unit_trained': // replace with your actual event type
        return Colors.yellow; // replace with the desired color
      case 'unit_added': // replace with your actual event type
        return Colors.orange; // replace with the desired color
      case 'building_level_up': // replace with your actual event type
        return Colors.grey; // replace with the desired color

    // add as many cases as you need
      default:
        return Colors.white; // default color if the event type doesn't match any case
    }
  }
}
