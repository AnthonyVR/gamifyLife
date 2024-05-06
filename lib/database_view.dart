import 'package:flutter/material.dart';
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

  int? selectedVersion; // Holds the selected backup version
  final List<int> availableVersions = List.generate(31, (index) => index + 1); // Example list of versions


  @override
  void initState() {
    super.initState();
    _loadTables();
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
          DropdownButton<int>(
            value: selectedVersion,
            hint: Text("Select Version"),
            onChanged: (int? newValue) {
              setState(() {
                selectedVersion = newValue;
              });
            },
            items: availableVersions.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text("Version $value"),
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
                  setState(() {
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Failed to restore database: $e"),
                  ));
                }
              } : null,
              child: Text("Restore database")),
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
