import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../services/database_helper.dart';

class FarmView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm'),
      ),
      body: ListView.builder(
        itemCount: 10, // Again, just a placeholder value
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text('Word $index'),
          );
        },
      ),
    );
  }
}