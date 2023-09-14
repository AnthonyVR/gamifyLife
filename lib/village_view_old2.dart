// import 'package:flutter/material.dart';
// import 'package:habit/barracks_view.dart';
// import 'package:habit/farm_view.dart';
// import '../models/tile.dart';
// import '../services/database_helper.dart';
// import 'models/village.dart';
//
// class VillageView extends StatefulWidget {
//   const VillageView({Key? key}) : super(key: key);
//
//   @override
//   _VillageViewState createState() => _VillageViewState();
// }
//
// class _VillageViewState extends State<VillageView> {
//   final String grassImage = 'assets/village_package/tiles/medievalTile_57.png';
//   final String rock = 'assets/village_package/environment/medievalEnvironment_07.png';
//   int gridSizeWidth = 1;
//   int gridSizeHeight = 1;
//   late Village villageInstance; // Instance to interface with the Village model
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     const tileSize = 40.0;
//
//     gridSizeWidth = (screenWidth / tileSize).floor();
//     gridSizeHeight = (screenHeight / tileSize).floor();
//
//     villageInstance = Village.getVillageById(1);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Your UI code (unchanged)
//     // ...
//
//     // Update FutureBuilders to use methods from the villageInstance
//     // For example:
//     FutureBuilder<Village?>(
//       future: villageInstance,
//       // ...
//     );
//
//     FutureBuilder<Map<int, Map<int, Map<String, dynamic>>>>(
//       future: villageInstance.fetchTileMapFromDB(),
//       // ...
//     );
//   }
//
// // The view doesn't handle direct database operations anymore.
// // Instead, it interfaces with the Village model which in turn interacts with the database.
// }
