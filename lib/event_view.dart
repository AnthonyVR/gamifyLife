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
      return DateFormat('d MMMM y, HH:mm').format(dateTime);  // Adjust format as needed
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
            if (snapshot.hasData) {
              // Sort the events by timestamp in descending order
              snapshot.data!.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              final eventList = snapshot.data!;
              return ListView.builder(
                itemCount: eventList.length,
                itemBuilder: (context, index) {
                  final event = eventList[index];

                  // Check if the event type is "unit_trained"
                  // if (event.eventType == "unit_trained" || event.eventType == 'unit_added' || event.eventType == 'building_level_up') {
                  //   return Text("?", textAlign: TextAlign.center,); // Return an empty widget if the condition is met
                  // }

                  // If the event type is not "unit_trained", display the content
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: ListTile(
                      onLongPress: () =>  (event.eventType == "unit_trained" || event.eventType == 'unit_added' || event.eventType == 'building_level_up') ? "" : showInfoDialog(context, event.info), // Call the function on long press
                      tileColor: _getColorForEventType(event.eventType),
                      title: Text(formatTimestamp(event.timestamp.toIso8601String())),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Spacer(), // This will take up all available space between the text widgets
                              (event.eventType == "unit_trained" || event.eventType == 'unit_added' || event.eventType == 'building_level_up') ? Text("?") : Text(event.eventType),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text("No events found"));
            }
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  void showInfoDialog(BuildContext context, Map<dynamic, dynamic> info) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details'), // Optional: Add a title
          content: SingleChildScrollView( // Makes the dialog scrollable if content is too long
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: info.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.0), // Spacing between each row
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)), // Key with bold style
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(' ${entry.value.toString()}'), // Value
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }



  Color _getColorForEventType(String eventType) {
    switch(eventType) {
      case 'village_spawn':
        return Colors.blue;
      case 'attack': // replace with your actual event type
        return Colors.red; // replace with the desired color
      // case 'unit_trained': // replace with your actual event type
      //   return Colors.yellow; // replace with the desired color
      // case 'unit_added': // replace with your actual event type
      //   return Colors.orange; // replace with the desired color
      // case 'building_level_up': // replace with your actual event type
      //   return Colors.grey; // replace with the desired color

    // add as many cases as you need
      default:
        return Colors.white; // default color if the event type doesn't match any case
    }
  }
}
