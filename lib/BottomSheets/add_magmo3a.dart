
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';

class AddMagmo3a extends StatefulWidget {
  AddMagmo3a({super.key});

  @override
  _AddMagmo3aState createState() => _AddMagmo3aState();
}

class _AddMagmo3aState extends State<AddMagmo3a> {
  TimeOfDay _timeOfDay = TimeOfDay.now(); ////
  String? _selectedSecondary; ////
  String?type;
  String? _chosenDay; ////
   final List<String> _days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];
  final List<String> _secondaries = [
    '1 secondary',
    '2 secondary',
    '3 secondary',
  ];

   ///////
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: app_colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              //days picker
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        " D A Y S ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton(
                      dropdownColor: app_colors.green,
                      value: _chosenDay,
                      isExpanded: true,
                      // This will make the dropdown take the whole width
                      hint: const Text("Select a day",
                          style: TextStyle(color: app_colors.green)),
                      // This will display "Select a day" when no day is selected
                      items: _days.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day,
                              style: const TextStyle(color: app_colors.orange)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _chosenDay = value as String?;
                        });
                      },
                      underline: Container(
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: app_colors.orange, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      elevation: 8,
                      style: const TextStyle(color: app_colors.orange),
                      icon: const Icon(Icons.arrow_forward_ios_outlined,
                          color: app_colors.orange),
                      iconSize: 24,
                    ),
                  ),
                  _chosenDay != null
                      ? Chip(
                    backgroundColor: app_colors.green,
                    label: Text(_chosenDay!,
                        style: const TextStyle(color: app_colors.orange)),
                    deleteIcon: const Icon(Icons.cancel,
                        size: 20, color: app_colors.orange),
                    shape: const StadiumBorder(
                        side: BorderSide(color: app_colors.orange)),
                    onDeleted: () {
                      setState(() {
                        _chosenDay = null;
                      });
                    },
                  )
                      : const Text("Select a day",
                      style: TextStyle(color: app_colors.green)),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              const Divider(
                color: app_colors.green,
                thickness: 3,
              ),
              // time picker
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        " T I M E ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _ShowTimePicker,
                        child: Container(
                          decoration: BoxDecoration(
                              color: app_colors.orange,
                              borderRadius: BorderRadius.circular(25),
                              border: const Border.fromBorderSide(BorderSide(
                                  color: app_colors.green, width: 1.5))),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(" Pick Time "),
                          ),
                        ),
                      ),
                      Text(
                        "${_timeOfDay.hour > 12 ? _timeOfDay.hour - 12 : _timeOfDay.hour}:${_timeOfDay.minute.toString().padLeft(2, '0')} ${_timeOfDay.hour >= 12 ? 'PM' : 'AM'}",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 30),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              const Divider(
                color: app_colors.green,
                thickness: 3,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        " G R A D E ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButton(
                    dropdownColor: app_colors.green,
                    value: _selectedSecondary,
                    isExpanded: true,
                    hint: const Text("Select a secondary",
                        style: TextStyle(color: app_colors.green)),
                    items: _secondaries.map((secondary) {
                      return DropdownMenuItem(
                        value: secondary,
                        child: Text(secondary,
                            style: const TextStyle(color: app_colors.orange)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSecondary = value as String;
                      });
                    },
                    underline: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: app_colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    elevation: 8,
                    style: const TextStyle(color: app_colors.orange),
                    icon: const Icon(Icons.arrow_forward_ios_outlined,
                        color: app_colors.orange),
                    iconSize: 24,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _selectedSecondary != null
                      ? Wrap(
                          direction: Axis.horizontal,
                          spacing: 8,
                          children: [
                            Chip(
                              backgroundColor: app_colors.green,
                              label: Text(_selectedSecondary!,
                                  style: const TextStyle(color: app_colors.orange)),
                              deleteIcon: const Icon(Icons.cancel,
                                  size: 20, color: app_colors.orange),
                              shape: const StadiumBorder(
                                  side: BorderSide(color: app_colors.orange)),
                              onDeleted: () {
                                setState(() {
                                  _selectedSecondary = null;
                                });
                              },
                            ),
                          ],
                        )
                      : const Text("Select a secondary",
                          style: TextStyle(color: app_colors.green)),
                  const SizedBox(
                    height: 10,
                  ),

                ],
              ),
              const SizedBox(
                height: 30,
              ),


              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: app_colors.orange,
                        backgroundColor: app_colors.green, // text color
                      ),
                      onPressed: () async {
                        if (_chosenDay==null) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one day'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (_timeOfDay == TimeOfDay.now()) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a time'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (_selectedSecondary == null) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a grade'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        else {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(' added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Magmo3amodel magmo3amodel = Magmo3amodel(
                            userid: FirebaseAuth.instance.currentUser!.uid,
                              days: _chosenDay,
                              time: _timeOfDay,
                              grade: _selectedSecondary);
                          await FirebaseFunctions.addMagmo3aToDay(_chosenDay!,magmo3amodel).then((value) {
                            Navigator.pop(context);
                          }); // wait for the Future to complete
                        }
                      },
                      child: const Text(" A D D "),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _ShowTimePicker() {
    showTimePicker(context: context, initialTime: TimeOfDay.now())
        .then((onValue) {
      setState(() {
        _timeOfDay = onValue!;
      });
    });
  }
}
