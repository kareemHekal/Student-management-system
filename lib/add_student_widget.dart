import 'dart:ui';

import 'package:fatma_elorbany/pages/days/Forthday.dart';
import 'package:fatma_elorbany/pages/days/SecondDay.dart';
import 'package:fatma_elorbany/pages/days/ThirdDay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'cards/groupSmallCard.dart';
import 'colors_app.dart';
import 'firebase/firebase_functions.dart';
import 'models/Magmo3aModel.dart';
import 'models/Studentmodel.dart';
import 'pages/days/Firstday.dart';

class AddStudentTab_ extends StatefulWidget {
  String? level;

  AddStudentTab_({this.level, super.key});

  @override
  State<AddStudentTab_> createState() => _AddStudentTabState();
}

class _AddStudentTabState extends State<AddStudentTab_> {
  _AddStudentTabState();

  Magmo3amodel? Firstgroup;
  Magmo3amodel? Forthgroup;
  Magmo3amodel? Secondgroup;
  Magmo3amodel? Thirdgroup;
  String? firstDay;

  String getFormattedDate() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy_MM_dd').format(now);
  }
  String? firstDayId;
  TimeOfDay? firstDayTime;
  String? secondDay;
  String? secondDayId;
  TimeOfDay? secondDayTime;
  String? thirdDay;
  String? thirdDayId;
  String? forthday;
  String? forthdayid;
  TimeOfDay? forthdayTime;
  TimeOfDay? thirdDayTime;
  String? _selectedGender;
  bool? _secondMonth;
  bool? _firstMonth;
  bool? _thirdMonth;
  bool? _fourthMonth;
  bool? _fifthMonth;
  bool? _explainingNote;
  bool? _reviewNote;
  TextEditingController name_controller = TextEditingController();
  TextEditingController studentNumberController = TextEditingController();
  TextEditingController fatherNumberController = TextEditingController();
  TextEditingController motherNumberController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget _buildVerticalLine() {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: app_colors.orange,
            borderRadius: BorderRadius.circular(25),
          ),
          width: 5,
          height: 200,
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 17),
        child: Container(
          decoration: BoxDecoration(
            color: app_colors.white.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          width: double.infinity,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20, left: 0),
                            child: Text(
                              textAlign: TextAlign.start,
                              '''  A D D 
  Y O U R  S T U D E N T S''',
                              style: GoogleFonts.oswald(
                                fontSize: 30,
                                color: app_colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const Divider(
                        color: app_colors.orange,
                        thickness: 4,
                      ),
                      SizedBox(
                        height: 240, // or any other bounded height
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: Text(" Pick the days ")),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // First Group
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                                color: app_colors.orange,
                                                width: 1),
                                            foregroundColor: app_colors.orange,
                                            backgroundColor:
                                                app_colors.green, // text color
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Firstday(
                                                    level: widget.level),
                                              ),
                                            ).then((result) {
                                              if (result != null) {
                                                setState(() {
                                                  Firstgroup = result;
                                                  firstDay = Firstgroup?.days;
                                                  firstDayId = Firstgroup?.id;
                                                  firstDayTime =
                                                      Firstgroup?.time;
                                                });
                                                print(
                                                    'Received Group ID: ${result.id}');
                                              }
                                            });
                                          },
                                          child: const Text("First Day"),
                                        ),
                                        Container(
                                          child: Firstgroup != null
                                              ? SizedBox(
                                                  width: 150,
                                                  // Example width, you can adjust this to your needs
                                                  height: 150,
                                                  child: Groupsmallcard(
                                                    magmo3aModel: Firstgroup,
                                                  ),
                                                )
                                              : const Center(
                                                  child: SizedBox(
                                                  height: 0,
                                                )),
                                        ),
                                      ],
                                    ),
                                    _buildVerticalLine(),
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                                color: app_colors.orange,
                                                width: 1),
                                            foregroundColor: app_colors.orange,
                                            backgroundColor:
                                                app_colors.green, // text color
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Secondday(
                                                    level: widget.level),
                                              ),
                                            ).then((result) {
                                              if (result != null) {
                                                setState(() {
                                                  Secondgroup = result;
                                                  secondDay = Secondgroup?.days;
                                                  secondDayId = Secondgroup?.id;
                                                  secondDayTime =
                                                      Secondgroup?.time;
                                                });
                                                print(
                                                    'Received Group ID: ${result.id}');
                                              }
                                            });
                                          },
                                          child: const Text("Second Day"),
                                        ),
                                        Container(
                                          child: Secondgroup != null
                                              ? SizedBox(
                                                  width: 150,
                                                  // Example width, you can adjust this to your needs
                                                  height: 150,
                                                  child: Groupsmallcard(
                                                    magmo3aModel: Secondgroup,
                                                  ),
                                                )
                                              : const Center(child: SizedBox()),
                                        ),
                                      ],
                                    ),
                                    _buildVerticalLine(),
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                                color: app_colors.orange,
                                                width: 1),
                                            foregroundColor: app_colors.orange,
                                            backgroundColor:
                                                app_colors.green, // text color
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Thirdday(
                                                    level: widget.level),
                                              ),
                                            ).then((result) {
                                              if (result != null) {
                                                setState(() {
                                                  Thirdgroup = result;
                                                  thirdDay = Thirdgroup?.days;
                                                  thirdDayId = Thirdgroup?.id;
                                                  thirdDayTime =
                                                      Thirdgroup?.time;
                                                });
                                                print(
                                                    'Received Group ID: ${result.id}');
                                              }
                                            });
                                          },
                                          child: const Text("Third Day"),
                                        ),
                                        Container(
                                          child: Thirdgroup != null
                                              ? SizedBox(
                                                  width: 150,
                                                  // Example width, you can adjust this to your needs
                                                  height: 150,
                                                  child: Groupsmallcard(
                                                    magmo3aModel: Thirdgroup,
                                                  ),
                                                )
                                              : const Center(child: SizedBox()),
                                        ),
                                      ],
                                    ),
                                    _buildVerticalLine(),
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                              color: app_colors.orange,
                                              width: 1,
                                            ),
                                            foregroundColor: app_colors.orange,
                                            backgroundColor:
                                                app_colors.green, // text color
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Forthday(
                                                  level: widget.level,
                                                ),
                                              ),
                                            ).then((result) {
                                              if (result != null) {
                                                setState(() {
                                                  Forthgroup = result;
                                                  forthday = Forthgroup?.days;
                                                  forthdayid = Forthgroup?.id;
                                                  forthdayTime =
                                                      Forthgroup!.time;
                                                });
                                                print(
                                                    'Received Group ID: ${result.id}');
                                              }
                                            });
                                          },
                                          child: const Text("Forth Day"),
                                        ),
                                        Container(
                                          child: Forthgroup != null
                                              ? SizedBox(
                                                  width: 150,
                                                  // Example width, you can adjust this to your needs
                                                  height: 150,
                                                  child: Groupsmallcard(
                                                    magmo3aModel: Forthgroup,
                                                  ),
                                                )
                                              : const Center(child: SizedBox()),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        color: app_colors.orange,
                        thickness: 4,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: name_controller,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: " Student Name ",
                          labelStyle:
                              const TextStyle(fontSize: 25, color: app_colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: studentNumberController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your student number';
                          }
                          // You can add additional validation for student number format if needed
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Student Number",
                          labelStyle:
                              const TextStyle(fontSize: 25, color: app_colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        // to allow only numbers
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ], // to allow only digits
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: fatherNumberController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your father\'s number';
                          }
                          // You can add additional validation for phone number format if needed
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Father's Number",
                          labelStyle:
                              const TextStyle(fontSize: 25, color: app_colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        // to allow phone number input
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ], // to allow only digits
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: motherNumberController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mother\'s number';
                          }
                          // You can add additional validation for phone number format if needed
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Mother's Number",
                          labelStyle:
                              const TextStyle(fontSize: 25, color: app_colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        // to allow phone number input
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ], // to allow only digits
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Divider(
                        color: app_colors.orange,
                        thickness: 4,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: app_colors.green, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            dropdownColor: app_colors.green,
                            value: _selectedGender ?? "Male",
                            // Set the default value to "Male"
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: "Male",
                                child: Text("Male",
                                    style: TextStyle(color: app_colors.orange)),
                              ),
                              DropdownMenuItem(
                                value: "Female",
                                child: Text("Female",
                                    style: TextStyle(color: app_colors.orange)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value as String;
                              });
                            },
                            elevation: 8,
                            style: const TextStyle(color: app_colors.orange),
                            icon: const Icon(Icons.arrow_forward_ios_outlined,
                                color: app_colors.orange),
                            iconSize: 24,
                            hint: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                _selectedGender ?? "Select a gender",
                                style: const TextStyle(color: app_colors.orange),
                              ),
                            ),
                          )),
                      const SizedBox(
                        height: 15,
                      ),
                      _selectedGender != null
                          ? Wrap(
                              direction: Axis.horizontal,
                              spacing: 8,
                              children: [
                                Chip(
                                  backgroundColor: app_colors.green,
                                  label: Text(_selectedGender!,
                                      style:
                                          const TextStyle(color: app_colors.orange)),
                                  deleteIcon: const Icon(Icons.cancel,
                                      size: 20, color: app_colors.orange),
                                  shape: const StadiumBorder(
                                      side:
                                          BorderSide(color: app_colors.orange)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedGender = null;
                                    });
                                  },
                                ),
                              ],
                            )
                          : const Center(
                              child: Text("Select a gender",
                                  style: TextStyle(color: app_colors.orange)),
                            ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Divider(
                        color: app_colors.orange,
                        thickness: 4,
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        const Text("First Month :"),
                                        buildDropdown(
                                            "First Month", _firstMonth,
                                            (value) {
                                          setState(() {
                                            _firstMonth = value;
                                          });
                                        }),
                                      ],
                                    ),
                                    const SizedBox(width: 16.0),
                                    Column(
                                      children: [
                                        const Text("Second Month :"),
                                        buildDropdown(
                                            "Second Month", _secondMonth,
                                            (value) {
                                          setState(() {
                                            _secondMonth = value;
                                          });
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        const Text("Third Month :"),
                                        buildDropdown(
                                            "Third Month", _thirdMonth,
                                            (value) {
                                          setState(() {
                                            _thirdMonth = value;
                                          });
                                        }),
                                      ],
                                    ),
                                    const SizedBox(width: 16.0),
                                    Column(
                                      children: [
                                        const Text("Fourth Month :"),
                                        buildDropdown(
                                            "Fourth Month", _fourthMonth,
                                            (value) {
                                          setState(() {
                                            _fourthMonth = value;
                                          });
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        const Text("Fifth Month :"),
                                        buildDropdown(
                                            "Fifth Month", _fifthMonth,
                                            (value) {
                                          setState(() {
                                            _fifthMonth = value;
                                          });
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        const Text("Explaining Note :"),
                                        buildDropdown(
                                            "Explaining Note", _explainingNote,
                                            (value) {
                                          setState(() {
                                            _explainingNote = value;
                                          });
                                        }),
                                      ],
                                    ),
                                    const SizedBox(width: 16.0),
                                    Column(
                                      children: [
                                        const Text("Reviewing Note :"),
                                        buildDropdown(
                                            "Review Note", _reviewNote,
                                            (value) {
                                          setState(() {
                                            _reviewNote = value;
                                          });
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        color: app_colors.orange,
                        thickness: 4,
                      ),const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: noteController,
                        maxLines: 3, // Allows for multi-line input
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a note';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Add Note",
                          labelStyle:
                              const TextStyle(fontSize: 25, color: app_colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: app_colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          hintText: 'Type your note here...',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: app_colors.orange,
                                backgroundColor: app_colors.green, // text color
                              ),
                              onPressed: () {
                                if (Firstgroup == null &&
                                    Secondgroup == null &&
                                    Thirdgroup == null&&
                                    Forthgroup==null
                                ) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Please pick at least one group'),
                                    ),
                                  );
                                  return; // Early return to prevent further actions
                                }

// Proceed with your logic if at least one group is selected

                                // Check if all the form fields are filled
                                if (name_controller.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text(
                                            'Please enter the student\'s name')),
                                  );
                                  return;
                                }
                                if (studentNumberController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Please enter the student number'),
                                    ),
                                  );
                                  return;
                                }

// Validate that student number is exactly 11 digits
                                if (!RegExp(r'^\d{11}$')
                                    .hasMatch(studentNumberController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Student number must be exactly 11 digits'),
                                    ),
                                  );
                                  return;
                                }

                                if (fatherNumberController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Please enter the father\'s number'),
                                    ),
                                  );
                                  return;
                                }

// Validate that father's number is exactly 11 digits
                                if (!RegExp(r'^\d{11}$')
                                    .hasMatch(fatherNumberController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Father\'s number must be exactly 11 digits'),
                                    ),
                                  );
                                  return;
                                }

                                if (motherNumberController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Please enter the mother\'s number'),
                                    ),
                                  );
                                  return;
                                }

// Validate that mother's number is exactly 11 digits
                                if (!RegExp(r'^\d{11}$')
                                    .hasMatch(motherNumberController.text)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text(
                                          'Mother\'s number must be exactly 11 digits'),
                                    ),
                                  );
                                  return;
                                }

                                if (_selectedGender == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content:
                                            Text('Please select a gender')),
                                  );
                                  return;
                                }
                                if (_firstMonth == null ||
                                    _secondMonth == null ||
                                    _thirdMonth == null ||
                                    _fifthMonth == null ||
                                    _fourthMonth == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text(
                                            'Please select payment status for all months')),
                                  );
                                  return;
                                }
                                if (_explainingNote == null ||
                                    _reviewNote == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text(
                                            'Please select notes for explaining and reviewing')),
                                  );
                                  return;
                                }

                                // If all validations pass, proceed with your logic here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      backgroundColor: Colors.green,
                                      content:
                                          Text('Student added successfully!')),
                                );
                                Studentmodel submodel = Studentmodel(
                                  firstDay: firstDay,
                                  forthdayTime: forthdayTime,
                                  note: noteController.text.isEmpty ? "No note" : noteController.text,
                                  dateofadd: getFormattedDate(),
                                  forthday: forthday,
                                  forthdayid: forthdayid,
                                  firstDayId: firstDayId,
                                  thirdDayId: thirdDayId,
                                  secondDayId: secondDayId,
                                  firstDayTime: firstDayTime,
                                  secondDay: secondDay,
                                  secondDayTime: secondDayTime,
                                  thirdDay: thirdDay,
                                  thirdDayTime: thirdDayTime,
                                  name: name_controller.text,
                                  gender: _selectedGender,
                                  grade: widget.level,
                                  firstMonth: _firstMonth,
                                  secondMonth: _secondMonth,
                                  thirdMonth: _thirdMonth,
                                  fourthMonth: _firstMonth,
                                  fifthMonth: _fifthMonth,
                                  explainingNote: _explainingNote,
                                  reviewNote: _reviewNote,
                                  phoneNumber: studentNumberController.text,
                                  motherPhone: motherNumberController.text,
                                  fatherPhone: fatherNumberController.text,
                                );
                                FirebaseFunctions.addStudentToCollection(
                                    widget.level??"",submodel);
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/HomeScreen',
                                  (route) => false,
                                );
                              },
                              child: const Text(" Add "),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 200,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget buildDropdown(
    String hint,
    bool? selectedValue,
    ValueChanged<bool?> onChanged,
  ) {
    return SizedBox(
      width: 200, // specify a width
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: app_colors.green, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<bool>(
          dropdownColor: app_colors.green,
          value: selectedValue,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: true,
              child: Text("Paid", style: TextStyle(color: Colors.orange)),
            ),
            DropdownMenuItem(
              value: false,
              child: Text("Not Paid", style: TextStyle(color: Colors.orange)),
            ),
          ],
          onChanged: onChanged,
          elevation: 8,
          style: const TextStyle(color: Colors.orange),
          icon: const Icon(Icons.arrow_forward_ios_outlined, color: Colors.orange),
          iconSize: 24,
          hint: Text(
            selectedValue == null
                ? hint
                : (selectedValue ? "Paid" : "Not Paid"),
            style: const TextStyle(color: Colors.orange),
          ),
        ),
      ),
    );
  }
}
