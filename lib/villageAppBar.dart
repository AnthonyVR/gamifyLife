import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habit/village_view.dart';

import 'models/village.dart';

class VillageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<Village?> Function() getVillage;
  final String? titleText;

  VillageAppBar({
    required this.getVillage,
    this.titleText,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // This will hide the back button
      backgroundColor: const Color(0xFFb87a3d),
      title: FutureBuilder<Village?>(
        future: getVillage(),
        builder: (context, villageSnapshot) {
          if (villageSnapshot.connectionState == ConnectionState.done) {
            if (villageSnapshot.hasError) {
              return Text('Error');
            }
            if (!villageSnapshot.hasData || villageSnapshot.data == null) {
              return Text('No Village Data');
            }

            String displayTitle = villageSnapshot.data!.name;
            if (titleText != null) {
              displayTitle = titleText!;  // Override with provided title if available
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/coins.svg',
                      width: 25,
                      height: 25,
                    ),
                    SizedBox(width: 5,),
                    Text("${villageSnapshot.data?.coins}", style: TextStyle(fontSize: 28),),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VillageView(villageId: 1),
                        fullscreenDialog: true, // make the page full screen
                      ),
                    );
                  },
                  icon: Icon(Icons.arrow_left),
                ),
                Text(displayTitle),
                IconButton(
                  onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VillageView(villageId: 2),
                          fullscreenDialog: true, // make the page full screen
                        ),
                      );
                      },
                  icon: Icon(Icons.arrow_right),
                ),
                FutureBuilder<int?>(
                  future: villageSnapshot.data!.getPopulation(),
                  builder: (context, populationSnapshot) {
                    if (populationSnapshot.connectionState == ConnectionState.done) {
                      if (!populationSnapshot.hasData || populationSnapshot.data == null) {
                        return Text('(No population data)');
                      }
                      return FutureBuilder<int?>(
                        future: villageSnapshot.data!.getCapacity(),
                        builder: (context, capacitySnapshot) {
                          if (capacitySnapshot.connectionState == ConnectionState.done) {
                            if (!capacitySnapshot.hasData || capacitySnapshot.data == null) {
                              return Text('${populationSnapshot.data} / (No capacity data)');
                            }
                            return Text('${populationSnapshot.data} / ${capacitySnapshot.data}');
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                )
              ],
            );

          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
