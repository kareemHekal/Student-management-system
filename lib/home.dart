import 'package:chips_choice/chips_choice.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Nav_Bar_Tabs/Add_student_tab.dart';
import 'Nav_Bar_Tabs/students_tab.dart';
import 'colors_app.dart';
import 'firebase/firebase_functions.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  bool isDangresAreaOpen = false;
  int _currant_index = 0;
  List<String> tags = [];
  List<String> options = [
    '1 secondary',
    '2 secondary',
    '3 secondary',
    'Absence',
  ];
  final List<Widget> _bodytabs = [
    const StudentsTab(),
    const AddStudentTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            // Part 1: Two images in a row
            Container(
              decoration: const BoxDecoration(
                color: app_colors.green,
              ),
              width: double.infinity,
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Image.asset(
                    "assets/images/1......1.png",
                    height: 120,
                    width: 120,
                  ),
                  Text(
                    "Ibrahim yassin",
                    style: GoogleFonts.qwitcherGrypen(
                        color: Colors.white, fontSize: 50),
                  )
                  // add some space between images
                ],
              ),
            ),

            // Part 2: ListView with light green background and title
            Expanded(
              child: Container(
                color: app_colors.ligthGreen, // light green background
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/StudentsTab', (route) => false);
                      },
                      child: ListTile(
                        leading: Image.asset("assets/images/students.png",
                            width: 50),
                        title: const Text(
                          "All Students",
                          style:
                              TextStyle(color: app_colors.green, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        FirebaseFunctions.resetAttendanceForAllStudents();
                      },
                      child: ListTile(
                        leading:
                            Image.asset("assets/images/restart.png", width: 50),
                        title: const Text(
                          "Start New Month",
                          style:
                              TextStyle(color: app_colors.green, fontSize: 18),
                        ),
                      ),
                    ) // add more list items here
                  ],
                ),
              ),
            ),

            // Part 3: Two buttons at the bottom
            GestureDetector(
              onTap: () {
                isDangresAreaOpen = !isDangresAreaOpen;
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[50],
                ),
                width: double.maxFinite, // <--- Add this line
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDangresAreaOpen == false
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.keyboard_double_arrow_down_rounded,
                        color: Colors.red[400],
                      ),
                      const Spacer(),
                      const Text(
                        "Dangerous Zone",
                        style: TextStyle(color: Colors.red, fontSize: 20),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Container(
                color: Colors.red[50],
                child: isDangresAreaOpen == true
                    ? Column(
                        children: [
                          const Divider(
                            endIndent: 15,
                            indent: 15,
                            color: Colors.red,
                            thickness: 2,
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text("Sign out",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 20)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffFF0000),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10), // rectangular shape with rounded corners
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    // center the row
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Text(
                                        "sign out",
                                        style: TextStyle(
                                            color: app_colors.white,
                                            fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    FirebaseAuth.instance.signOut();
                                    Navigator.pushNamedAndRemoveUntil(context,
                                        '/LoginPage', (route) => false);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            endIndent: 8,
                            indent: 8,
                            color: Colors.red,
                            thickness: 2,
                          ),
                          // delete  part
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text("Delete Every Thing",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 20)),
                              ),
                              ChipsChoice<String>.multiple(
                                value: tags,
                                onChanged: (val) {
                                  setState(() {
                                    tags = val;
                                    print(tags); // Print the tags list
                                  });
                                },
                                choiceItems: C2Choice.listFrom<String, String>(
                                  source: options,
                                  value: (i, v) => v,
                                  label: (i, v) => v,
                                ),
                                choiceStyle: C2ChipStyle.outlined(
                                  borderWidth: 2,
                                  backgroundColor: Colors.black,
                                  // Text color for unselected chips
                                  selectedStyle: const C2ChipStyle(
                                    borderColor: Colors.redAccent,
                                    // Border color for selected chips
                                    foregroundColor: Colors.redAccent,
                                    // Text color for selected chips
                                    backgroundColor: Colors
                                        .white, // Background color for selected chips
                                  ),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xffFF0000),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // rectangular shape with rounded corners
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      // center the row
                                      children: [
                                        Icon(
                                          Icons.delete_sweep_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        Text(
                                          "Delete Things you choose",
                                          style: TextStyle(
                                              color: app_colors.white,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.red[50],
                                            title: const Text(
                                              "Are you sure?",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                            content: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              // Ensures the dialog takes minimum height based on content
                                              children: [
                                                Text(
                                                  "This will delete the data you just chose. Are you sure?",
                                                  style: TextStyle(
                                                    color: Colors.red[
                                                        400], // Color for the first part of the text
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Adds some space between the text and the tags
                                                Text(
                                                  "You selected: ${tags?.isEmpty ?? true ? "NoThing" : tags.join(', ')}",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .red, // Changed to red
                                                ),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red[50]),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .red, // Changed to red
                                                ),
                                                child: Text(
                                                  "Sure!",
                                                  style: TextStyle(
                                                      color: Colors.red[50]),
                                                ),
                                                onPressed: () async {
                                                  for (var tag in tags) {
                                                    // Check if the tag matches '1 secondary', '2 secondary', or '3 secondary'
                                                    if (tag == '1 secondary' ||
                                                        tag == '2 secondary' ||
                                                        tag == '3 secondary') {
                                                      // Call the delete function for the matched collection (e.g., delete the secondary collection)
                                                      await FirebaseFunctions
                                                          .deleteCollection(
                                                              tag); // This will delete the collection
                                                      print(
                                                          'Deleted collection: $tag');
                                                    } else {
                                                      // If the tag is not one of the "secondary" tags, delete absences for all days of the week
                                                      List<String>
                                                          allDaysOfWeek = [
                                                        "Monday",
                                                        "Tuesday",
                                                        "Wednesday",
                                                        "Thursday",
                                                        "Friday",
                                                        "Saturday",
                                                        "Sunday"
                                                      ];

                                                      // Loop through all days of the week and delete the absences subcollection for each group
                                                      for (var day
                                                          in allDaysOfWeek) {
                                                        await FirebaseFunctions
                                                            .deleteAbsencesSubcollection(
                                                                day); // Call the delete function for absences
                                                        print(
                                                            'Attempted to delete absences for $day');
                                                      }
                                                    }
                                                  }
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  )),
                            ],
                          ),
                        ],
                      )
                    : null)
          ],
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: app_colors.green,
        title: Image.asset(
          "assets/images/2....2.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 120,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              "assets/images/app.png", // Your icon image path
              height: 30, // Adjust the height as needed
              width: 30, // Adjust the width as needed
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
          ),
        ),
      ),
      body: _bodytabs[_currant_index],
      bottomNavigationBar: CurvedNavigationBar(
        animationCurve: Curves.linear,
        onTap: (index) {
          setState(() {
            _currant_index = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: app_colors.green,
        animationDuration: const Duration(milliseconds: 500),
        items: [
          Icon(Icons.home,
              color: _currant_index == 0 ? app_colors.orange : Colors.white),
          Icon(Icons.add,
              color: _currant_index == 1 ? app_colors.orange : Colors.white),
        ],
      ),
    );
  }
}
