import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '/services/database_helper.dart';

class DatabaseView extends StatefulWidget {
  @override
  _DatabaseViewState createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  List<String> _tables = [];
  List<Map<String, dynamic>> _selectedTableData = [];
  String? _selectedTable;

  String? selectedVersion; // Holds the selected backup version
  late List<String> availableVersions = ["hey", "hoi"]; //List.generate(31, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _loadTables();
    _loadBackupVersions();
  }

  Future<void> _loadBackupVersions() async {
    // Define the external storage directory for the backups
    Directory externalDir = Directory("/storage/emulated/0/Documents"); // or wherever you save the backups

    // Check if the backup directory exists
    if (!externalDir.existsSync()) {
      print("Backup directory does not exist at ${externalDir.path}");
      return;
    }

    // List the files in the external storage backup directory
    final files = externalDir.listSync();

    // Log the directory being scanned and the files found
    print("Looking for backups in directory: ${externalDir.path}");
    files.forEach((file) {
      print("Found file: ${file.path}"); // Each file found
    });

    // Update the state to reflect the available backup versions
    setState(() {
      availableVersions = files
          .where((item) => FileSystemEntity.isFileSync(item.path))
          .map((item) => item.path.split('/').last)
          .toList()
          .reversed
          .toList();
    });
  }



  Future<void> _loadTables() async {
    final db = await DatabaseHelper.instance.database;
    List<Map> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    setState(() {
      _tables = tables.map((table) => table['name'].toString()).toList();
    });
  }

  Future<void> _loadTableData(String tableName) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> data = await db.query(tableName);
    setState(() {
      _selectedTableData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Database Viewer")),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedVersion,
            hint: Text("Select Version"),
            onChanged: (String? newValue) {
              setState(() {
                selectedVersion = newValue;
              });
            },
            items: availableVersions.map<DropdownMenuItem<String>>((String fileName) {
              return DropdownMenuItem<String>(
                value: fileName,
                child: Text(fileName),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: selectedVersion != null ? () async {
              try {
                String status = await DatabaseHelper.instance.restoreDatabaseFromBackup(selectedVersion!);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(status),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Failed to restore database: $e"),
                ));
              }
            } : null,
            child: Text("Restore database"),
          ),
          Divider(),
          Text("Currently loaded database"),
          DropdownButton<String>(
            value: _selectedTable,
            onChanged: (value) {
              setState(() {
                _selectedTable = value!;
                _loadTableData(_selectedTable!);
              });
            },
            items: _tables.map((table) {
              return DropdownMenuItem<String>(
                value: table,
                child: Text(table),
              );
            }).toList(),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _selectedTableData.isNotEmpty
                    ? DataTable(
                  columns: _selectedTableData[0].keys
                      .map((key) => DataColumn(label: Text(key)))
                      .toList(),
                  rows: _selectedTableData.map((row) {
                    return DataRow(
                      cells: row.values
                          .map((value) => DataCell(Text(value.toString())))
                          .toList(),
                    );
                  }).toList(),
                )
                    : Center(child: Text("Select a table")),
              ),
            ),
          )
        ],
      ),
    );
  }
}
