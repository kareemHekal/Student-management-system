import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../cards/groupSmallCard.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';
import 'days/Firstday.dart';
import 'days/Forthday.dart';
import 'days/SecondDay.dart';
import 'days/ThirdDay.dart';

class EditStudentScreen extends StatefulWidget {
  Studentmodel student;
  String? grade;

  EditStudentScreen({required this.student, required this.grade, super.key});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  Magmo3amodel? Firstgroup;
  Magmo3amodel? Secondgroup;
  Magmo3amodel? Thirdgroup;
  Magmo3amodel? Forthgroup;
  String?forthday;
  String?forthdayid;
  TimeOfDay?forthdayTime;
  String? firstDay;
  String? firstDayId;
  TimeOfDay? firstDayTime;
  String? secondDay;
  String? secondDayId;
  TimeOfDay? secondDayTime;
  String? thirdDay;
  String? thirdDayId;
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
  @override
  void initState() {
    super.initState();
    noteController.text = widget.student.note ?? "";
    name_controller.text = widget.student.name ?? "";
    studentNumberController.text = widget.student.phoneNumber ?? "";
    fatherNumberController.text = widget.student.fatherPhone ?? "";
    motherNumberController.text = widget.student.motherPhone ?? "";

    // Initialize months and notes
    _firstMonth = widget.student.firstMonth;
    _secondMonth = widget.student.secondMonth;
    _thirdMonth = widget.student.thirdMonth;
    _fourthMonth = widget.student.fourthMonth;
    _fifthMonth = widget.student.fifthMonth;
    _explainingNote = widget.student.explainingNote;
    _reviewNote = widget.student.reviewNote;

    // Initialize gender
    _selectedGender = widget.student.gender;

    // Initialize groups and days (if these exist in the student model)
    Firstgroup = (widget.student.firstDay != null)
        ? Magmo3amodel(
        days: widget.student.firstDay,
        grade: widget.student.grade,
        time: widget.student.firstDayTime)
        : null;

    Secondgroup = (widget.student.secondDay != null)
        ? Magmo3amodel(
        days: widget.student.secondDay,
        grade: widget.student.grade,
        time: widget.student.secondDayTime)
        : null;

    Thirdgroup = (widget.student.thirdDay != null)
        ? Magmo3amodel(
        days: widget.student.thirdDay,
        grade: widget.student.grade,
        time: widget.student.thirdDayTime)
        : null;

    Forthgroup = (widget.student.forthday != null)
        ? Magmo3amodel(
        days: widget.student.forthday,
        grade: widget.student.grade,
        time: widget.student.forthdayTime)
        : null;

    firstDay = widget.student.firstDay;
    firstDayId = widget.student.firstDayId;
    firstDayTime = widget.student.firstDayTime != null
        ? TimeOfDay(
        hour: widget.student.firstDayTime!.hour,
        minute: widget.student.firstDayTime!.minute)
        : null;

    secondDay = widget.student.secondDay;
    secondDayId = widget.student.secondDayId;
    secondDayTime = widget.student.secondDayTime != null
        ? TimeOfDay(
        hour: widget.student.secondDayTime!.hour,
        minute: widget.student.secondDayTime!.minute)
        : null;

    thirdDay = widget.student.thirdDay;
    thirdDayId = widget.student.thirdDayId;
    thirdDayTime = widget.student.thirdDayTime != null
        ? TimeOfDay(
        hour: widget.student.thirdDayTime!.hour,
        minute: widget.student.thirdDayTime!.minute)
        : null;

    forthday = widget.student.forthday;
    forthdayid = widget.student.forthdayid;
    forthdayTime = widget.student.forthdayTime != null
        ? TimeOfDay(
        hour: widget.student.forthdayTime!.hour,
        minute: widget.student.forthdayTime!.minute)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    Widget buildVerticalLine() {
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

    return Material(
      child: Scaffold(
          appBar: AppBar(
            elevation: 10,
            shadowColor: Colors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: app_colors.orange),
            ),
            backgroundColor: app_colors.green,
            title: Image.asset(
              "assets/images/2....2.png",
              height: 100,
              width: 90,
            ),
            toolbarHeight: 180,
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Center(child: Image.asset("assets/images/1......1.png")),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 17),
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
                                      padding: const EdgeInsets.only(
                                          top: 20, left: 0),
                                      child: Text(
                                        textAlign: TextAlign.start,
                                        '''  E D I T
  Y O U R  S T U D E N T S''',
                                        style: GoogleFonts.oswald(
                                          fontSize: 30,
                                          color: app_colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                  ],
                                ),
                                const Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                SizedBox(
                                  height: 240, // or any other bounded height
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Center(child: Text(" Pick the days ")),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.start,
                                            children: [
                                              // First Group
                                              Column(
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      side: const BorderSide(
                                                          color:
                                                          app_colors.orange,
                                                          width: 1),
                                                      foregroundColor:
                                                      app_colors.orange,
                                                      backgroundColor: app_colors
                                                          .green, // text color
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Firstday(
                                                                  level: widget
                                                                      .grade),
                                                        ),
                                                      ).then((result) {
                                                        if (result != null) {
                                                          updateGroup(
                                                              result, 'first');
                                                        }
                                                      });
                                                    },
                                                    child: Text("First Day"),
                                                  ),
                                                  Container(
                                                    child: Firstgroup != null
                                                        ? Container(
                                                      width: 150,
                                                      // Example width, you can adjust this to your needs
                                                      height: 150,
                                                      child:
                                                      Groupsmallcard(
                                                        magmo3aModel:
                                                        Firstgroup,
                                                      ),
                                                    )
                                                        : const Center(
                                                        child: SizedBox(
                                                          height: 0,
                                                        )),
                                                  ),
                                                ],
                                              ),
                                              buildVerticalLine(),
                                              Column(
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      side: const BorderSide(
                                                          color:
                                                          app_colors.orange,
                                                          width: 1),
                                                      foregroundColor:
                                                      app_colors.orange,
                                                      backgroundColor: app_colors
                                                          .green, // text color
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Secondday(
                                                                  level: widget
                                                                      .grade),
                                                        ),
                                                      ).then((result) {
                                                        if (result != null) {
                                                          updateGroup(
                                                              result, 'second');
                                                        }
                                                      });
                                                    },
                                                    child: const Text(
                                                        "Second Day"),
                                                  ),
                                                  Container(
                                                    child: Secondgroup != null
                                                        ? Container(
                                                      width: 150,
                                                      // Example width, you can adjust this to your needs
                                                      height: 150,
                                                      child:
                                                      Groupsmallcard(
                                                        magmo3aModel:
                                                        Secondgroup,
                                                      ),
                                                    )
                                                        : Center(
                                                        child: SizedBox()),
                                                  ),
                                                ],
                                              ),
                                              buildVerticalLine(),
                                              Column(
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      side: BorderSide(
                                                          color:
                                                          app_colors.orange,
                                                          width: 1),
                                                      foregroundColor:
                                                      app_colors.orange,
                                                      backgroundColor: app_colors
                                                          .green, // text color
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Thirdday(
                                                                  level: widget
                                                                      .grade),
                                                        ),
                                                      ).then((result) {
                                                        if (result != null) {
                                                          updateGroup(
                                                              result, 'third');
                                                        }
                                                      });
                                                    },
                                                    child: Text("Third Day"),
                                                  ),
                                                  Container(
                                                    child: Thirdgroup != null
                                                        ? Container(
                                                      width: 150,
                                                      // Example width, you can adjust this to your needs
                                                      height: 150,
                                                      child:
                                                      Groupsmallcard(
                                                        magmo3aModel:
                                                        Thirdgroup,
                                                      ),
                                                    )
                                                        : Center(
                                                        child: SizedBox()),
                                                  ),
                                                ],
                                              ),
                                              buildVerticalLine(),
                                              Column(
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      side: BorderSide(
                                                        color: app_colors
                                                            .orange,
                                                        width: 1,
                                                      ),
                                                      foregroundColor: app_colors
                                                          .orange,
                                                      backgroundColor:
                                                      app_colors
                                                          .green, // text color
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Forthday(
                                                                level: widget
                                                                    .grade,
                                                              ),
                                                        ),
                                                      ).then((result) {
                                                        if (result != null) {
                                                          setState(() {
                                                            Forthgroup = result;
                                                            forthday =
                                                                Forthgroup
                                                                    ?.days;
                                                            forthdayid =
                                                                Forthgroup?.id;
                                                            forthdayTime =
                                                                Forthgroup!
                                                                    .time;
                                                          });
                                                          print(
                                                              'Received Group ID: ${result
                                                                  .id}');
                                                        }
                                                      });
                                                    },
                                                    child: Text("Forth Day"),
                                                  ),
                                                  Container(
                                                    child: Forthgroup != null
                                                        ? Container(
                                                      width: 150,
                                                      // Example width, you can adjust this to your needs
                                                      height: 150,
                                                      child: Groupsmallcard(
                                                        magmo3aModel: Forthgroup,
                                                      ),
                                                    )
                                                        : Center(
                                                        child: SizedBox()),
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
                                Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                SizedBox(
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
                                    labelStyle: TextStyle(
                                        fontSize: 25, color: app_colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                ),
                                SizedBox(
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
                                    labelStyle: TextStyle(
                                        fontSize: 25, color: app_colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  // to allow only numbers
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ], // to allow only digits
                                ),
                                SizedBox(
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
                                    labelStyle: TextStyle(
                                        fontSize: 25, color: app_colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  // to allow phone number input
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ], // to allow only digits
                                ),
                                SizedBox(
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
                                    labelStyle: TextStyle(
                                        fontSize: 25, color: app_colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  // to allow phone number input
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ], // to allow only digits
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: app_colors.green, width: 1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButton<String>(
                                      dropdownColor: app_colors.green,
                                      value: _selectedGender ?? "Male",
                                      // Set the default value to "Male"
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem(
                                          child: Text("Male",
                                              style: TextStyle(
                                                  color: app_colors.orange)),
                                          value: "Male",
                                        ),
                                        DropdownMenuItem(
                                          child: Text("Female",
                                              style: TextStyle(
                                                  color: app_colors.orange)),
                                          value: "Female",
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value as String;
                                        });
                                      },
                                      elevation: 8,
                                      style:
                                      TextStyle(color: app_colors.orange),
                                      icon: Icon(
                                          Icons.arrow_forward_ios_outlined,
                                          color: app_colors.orange),
                                      iconSize: 24,
                                      hint: Padding(
                                        padding:
                                        const EdgeInsets.only(left: 10),
                                        child: Text(
                                          _selectedGender ?? "Select a gender",
                                          style: TextStyle(
                                              color: app_colors.orange),
                                        ),
                                      ),
                                    )),
                                SizedBox(
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
                                          style: TextStyle(
                                              color: app_colors.orange)),
                                      deleteIcon: Icon(Icons.cancel,
                                          size: 20,
                                          color: app_colors.orange),
                                      shape: StadiumBorder(
                                          side: BorderSide(
                                              color: app_colors.orange)),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedGender = null;
                                        });
                                      },
                                    ),
                                  ],
                                )
                                    : Center(
                                  child: Text("Select a gender",
                                      style: TextStyle(
                                          color: app_colors.orange)),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                SizedBox(
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
                                                  Text("First Month :"),
                                                  buildDropdown("First Month",
                                                      _firstMonth, (value) {
                                                        setState(() {
                                                          _firstMonth = value;
                                                        });
                                                      }),
                                                ],
                                              ),
                                              SizedBox(width: 16.0),
                                              Column(
                                                children: [
                                                  Text("Second Month :"),
                                                  buildDropdown("Second Month",
                                                      _secondMonth, (value) {
                                                        setState(() {
                                                          _secondMonth = value;
                                                        });
                                                      }),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16.0),
                                          Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Text("Third Month :"),
                                                  buildDropdown("Third Month",
                                                      _thirdMonth, (value) {
                                                        setState(() {
                                                          _thirdMonth = value;
                                                        });
                                                      }),
                                                ],
                                              ),
                                              SizedBox(width: 16.0),
                                              Column(
                                                children: [
                                                  Text("Fourth Month :"),
                                                  buildDropdown("Fourth Month",
                                                      _fourthMonth, (value) {
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
                                                  Text("Fifth Month :"),
                                                  buildDropdown("Fifth Month",
                                                      _fifthMonth, (value) {
                                                        setState(() {
                                                          _fifthMonth = value;
                                                        });
                                                      }),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16.0),
                                          Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Text("Explaining Note :"),
                                                  buildDropdown(
                                                      "Explaining Note",
                                                      _explainingNote, (value) {
                                                    setState(() {
                                                      _explainingNote = value;
                                                    });
                                                  }),
                                                ],
                                              ),
                                              SizedBox(width: 16.0),
                                              Column(
                                                children: [
                                                  const Text(
                                                      "Reviewing Note :"),
                                                  buildDropdown("Review Note",
                                                      _reviewNote, (value) {
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
                                ), const Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                /// the column of the monthes paid
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        showDateOfPaidMonth("First month",widget.student.dateOfFirstMonthPaid),
                                        showDateOfPaidMonth("Second month",widget.student.dateOfSecondMonthPaid),
                                      ],
                                    ),const SizedBox(
                                      height: 10,
                                    ),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        showDateOfPaidMonth("Third month",widget.student.dateOfThirdMonthPaid),
                                        showDateOfPaidMonth("Fourth month",widget.student.dateOfFourthMonthPaid),
                                      ],
                                    ),const SizedBox(
                                      height: 10,
                                    ),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        showDateOfPaidMonth("Fifth month",widget.student.dateOfFifthMonthPaid),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    showNumberOfAbsenceAndPresence("AttendantDays",widget.student.numberOfAttendantDays),
                                    showNumberOfAbsenceAndPresence("AbsentDays",widget.student.numberOfAbsentDays)
                                  ],
                                ),
                                const Divider(
                                  color: app_colors.orange,
                                  thickness: 4,
                                ),
                                const SizedBox(
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
                                    TextStyle(
                                        fontSize: 25, color: app_colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                      BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                      const BorderSide(
                                          color: app_colors.green, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    hintText: 'Type your note here...',
                                    hintStyle: TextStyle(color: Colors.grey),
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
                                          backgroundColor:
                                          app_colors.green, // text color
                                        ),
                                        onPressed: () {
                                          if (Firstgroup == null &&
                                              Secondgroup == null &&
                                              Thirdgroup == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Please pick at least one group'),
                                              ),
                                            );
                                            return; // Early return to prevent further actions
                                          }

                                          // Proceed with your logic if at least one group is selected

                                          // Check if all the form fields are filled
                                          if (name_controller.text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  backgroundColor:
                                                  Colors.redAccent,
                                                  content: Text(
                                                      'Please enter the student\'s name')),
                                            );
                                            return;
                                          }
                                          if (studentNumberController
                                              .text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Please enter the student number'),
                                              ),
                                            );
                                            return;
                                          }

                                          // Validate that student number is exactly 11 digits
                                          if (!RegExp(r'^\d{11}$').hasMatch(
                                              studentNumberController.text)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Student number must be exactly 11 digits'),
                                              ),
                                            );
                                            return;
                                          }

                                          if (fatherNumberController
                                              .text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Please enter the father\'s number'),
                                              ),
                                            );
                                            return;
                                          }

                                          // Validate that father's number is exactly 11 digits
                                          if (!RegExp(r'^\d{11}$').hasMatch(
                                              fatherNumberController.text)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Father\'s number must be exactly 11 digits'),
                                              ),
                                            );
                                            return;
                                          }

                                          if (motherNumberController
                                              .text.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Please enter the mother\'s number'),
                                              ),
                                            );
                                            return;
                                          }

                                          // Validate that mother's number is exactly 11 digits
                                          if (!RegExp(r'^\d{11}$').hasMatch(
                                              motherNumberController.text)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor:
                                                Colors.redAccent,
                                                content: Text(
                                                    'Mother\'s number must be exactly 11 digits'),
                                              ),
                                            );
                                            return;
                                          }

                                          if (_selectedGender == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  backgroundColor:
                                                  Colors.redAccent,
                                                  content: Text(
                                                      'Please select a gender')),
                                            );
                                            return;
                                          }
                                          if (_firstMonth == null ||
                                              _secondMonth == null ||
                                              _thirdMonth == null ||
                                              _fifthMonth == null ||
                                              _fourthMonth == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  backgroundColor:
                                                  Colors.redAccent,
                                                  content: Text(
                                                      'Please select payment status for all months')),
                                            );
                                            return;
                                          }
                                          if (_explainingNote == null ||
                                              _reviewNote == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  backgroundColor:
                                                  Colors.redAccent,
                                                  content: Text(
                                                      'Please select notes for explaining and reviewing')),
                                            );
                                            return;
                                          }

                                          // If all validations pass, proceed with your logic here
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                backgroundColor: Colors.green,
                                                content: Text(
                                                    'Student Edited successfully!')),
                                          );
                                          String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                                          String? dateOfFirstMonthPaid = _firstMonth != widget.student.firstMonth
                                              ? _firstMonth == true
                                              ? currentDate  // If changed to true, set to current date
                                              : null  // If changed to false, set to null
                                              : widget.student.dateOfFirstMonthPaid;

                                          String? dateOfSecondMonthPaid = _secondMonth != widget.student.secondMonth
                                              ? _secondMonth == true
                                              ? currentDate  // If changed to true, set to current date
                                              : null  // If changed to false, set to null
                                              : widget.student.dateOfSecondMonthPaid;

                                          String? dateOfThirdMonthPaid = _thirdMonth != widget.student.thirdMonth
                                              ? _thirdMonth == true
                                              ? currentDate  // If changed to true, set to current date
                                              : null  // If changed to false, set to null
                                              : widget.student.dateOfThirdMonthPaid;

                                          String? dateOfFourthMonthPaid = _fourthMonth != widget.student.fourthMonth
                                              ? _fourthMonth == true
                                              ? currentDate  // If changed to true, set to current date
                                              : null  // If changed to false, set to null
                                              : widget.student.dateOfFourthMonthPaid;

                                          String? dateOfFifthMonthPaid = _fifthMonth != widget.student.fifthMonth
                                              ? _fifthMonth == true
                                              ? currentDate  // If changed to true, set to current date
                                              : null  // If changed to false, set to null
                                              : widget.student.dateOfFifthMonthPaid;

                                          // Proceed with the rest of the logic to create the updated student model
                                          Studentmodel submodel = Studentmodel(
                                            id: widget.student.id,
                                            forthday: forthday,
                                            forthdayid: forthdayid,
                                            forthdayTime: forthdayTime,
                                            firstDayId: firstDayId,
                                            secondDayId: secondDayId,
                                            dateofadd: widget.student.dateofadd,
                                            thirdDayId: thirdDayId,
                                            firstDay: firstDay,
                                            firstDayTime: firstDayTime,
                                            secondDay: secondDay,
                                            secondDayTime: secondDayTime,
                                            thirdDay: thirdDay,
                                            thirdDayTime: thirdDayTime,
                                            name: name_controller.text,
                                            gender: _selectedGender,
                                            grade: widget.grade,
                                            firstMonth: _firstMonth,
                                            secondMonth: _secondMonth,
                                            thirdMonth: _thirdMonth,
                                            note: noteController.text,
                                            fourthMonth: _fourthMonth,
                                            fifthMonth: _fifthMonth,
                                            explainingNote: _explainingNote,
                                            reviewNote: _reviewNote,
                                            phoneNumber: studentNumberController.text,
                                            motherPhone: motherNumberController.text,
                                            fatherPhone: fatherNumberController.text,
                                            dateOfFirstMonthPaid: dateOfFirstMonthPaid,
                                            dateOfSecondMonthPaid: dateOfSecondMonthPaid,
                                            dateOfThirdMonthPaid: dateOfThirdMonthPaid,
                                            dateOfFourthMonthPaid: dateOfFourthMonthPaid,
                                            dateOfFifthMonthPaid: dateOfFifthMonthPaid,
                                          );;

                                          FirebaseFunctions
                                              .updateStudentInCollection(
                                              widget.student.grade ?? "",
                                              widget.student.id,
                                              submodel);

                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            '/HomeScreen',
                                                (route) => false,
                                          );
                                        },
                                        child: Text(" Edit "),
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
                  )),
            ],
          )),
    );
  }

  Widget showDateOfPaidMonth(String label,
      String? date,) {
   return Column(
      children: [
        Text(label,style: const TextStyle(),),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date ?? "he didn't pay for this yet", style: const TextStyle(
                fontSize: 10,
              color: app_colors.orange
            ),),
            const SizedBox(width:8),

          ],
        ),
      ],
    );
  }
  Widget showNumberOfAbsenceAndPresence(String label,
      int? number,) {
    return Column(
      children: [
        Text(label,style: const TextStyle(),),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (number ?? 0).toString(), style: const TextStyle(
                fontSize: 16,
                color: app_colors.orange
            ),),
            const SizedBox(width:8),

          ],
        ),
      ],
    );
  }
  Widget buildDropdown(String hint,
      bool? selectedValue,
      ValueChanged<bool?> onChanged,) {
    return SizedBox(
      width: 200, // specify a width
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: app_colors.green, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<bool>(
          dropdownColor: app_colors.green,
          value: selectedValue,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              child: Text("Paid", style: TextStyle(color: Colors.orange)),
              value: true,
            ),
            DropdownMenuItem(
              child: Text("Not Paid", style: TextStyle(color: Colors.orange)),
              value: false,
            ),
          ],
          onChanged: onChanged,
          elevation: 8,
          style: TextStyle(color: Colors.orange),
          icon: Icon(Icons.arrow_forward_ios_outlined, color: Colors.orange),
          iconSize: 24,
          hint: Text(
            selectedValue == null
                ? hint
                : (selectedValue ? "Paid" : "Not Paid"),
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ),
    );
  }

  void updateGroup(Magmo3amodel? result, String day) {
    setState(() {
      if (day == 'first') {
        Firstgroup = result;
        firstDay = Firstgroup?.days;
        firstDayId = Firstgroup?.id;
        firstDayTime = Firstgroup?.time;
      } else if (day == 'second') {
        Secondgroup = result;
        secondDay = Secondgroup?.days;
        secondDayId = Secondgroup?.id;
        secondDayTime = Secondgroup?.time;
      } else if (day == 'third') {
        Thirdgroup = result;
        thirdDay = Thirdgroup?.days;
        thirdDayId = Thirdgroup?.id;
        thirdDayTime = Thirdgroup?.time;
      }
    });
    print('Received Group ID: ${result?.id}');
  }
}
