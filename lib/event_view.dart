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
                    tileColor: event.eventType == 'village_spawn' ? Colors.blue : Colors.red,
                    title: Text(formatTimestamp(event.timestamp.toIso8601String())),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
}
