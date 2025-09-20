
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import 'add_student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  StudentCubit() : super(StudentInitial());

  ///============================================================================================================================\\\
  ///=============================================================Variables===========================================================\\\
  ///============================================================================================================================\\\
  late double totalAmount; // The total amount for the payment
  late String description; // The description of the payment
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController totalAmountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late String? date;
  late String? day;
  String? dateOfFirstMonthPaid;
  String? dateOfSecondMonthPaid;
  String? dateOfThirdMonthPaid;
  String? dateOfFourthMonthPaid;
  String? dateOfFifthMonthPaid;
  String? dateOfExplainingNotePaid;
  String? dateOfReviewingNotePaid;
  String? selectedGender;
  bool? secondMonth;
  bool? firstMonth;
  bool? thirdMonth;
  bool? fourthMonth;
  bool? fifthMonth;
  bool? explainingNote;
  bool? reviewNote;
  TextEditingController name_controller = TextEditingController();
  TextEditingController studentNumberController = TextEditingController();
  TextEditingController motherNumberController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  List<Magmo3amodel> hisGroups = [];
  List<String> hisGroupsId = []; // List of group IDs (Strings)
  ///============================================================================================================================\\\
  ///=============================================================Functions===========================================================\\\
  ///============================================================================================================================\\\
  static StudentCubit get(context) => BlocProvider.of(context);

  initTheState() {
    hisGroups = [];
    getCurrentDate();
  }

  Future<void> addStudent(BuildContext context, level) async {
    if (hisGroups.isEmpty) {
      emit(StudentValidationError("Please pick at least one group"));
      return;
    }

    if (name_controller.text.isEmpty) {
      emit(StudentValidationError("Please enter the student's name"));
      return;
    }
    if (studentNumberController.text.isEmpty) {
      emit(StudentValidationError("Please enter the student number"));
      return;
    }
    if (!RegExp(r'^\d{11}$').hasMatch(studentNumberController.text)) {
      emit(StudentValidationError("Student number must be exactly 11 digits"));
      return;
    }

    if (motherNumberController.text.isEmpty) {
      emit(StudentValidationError("Please enter the mother's number"));
      return;
    }
    if (!RegExp(r'^\d{11}$').hasMatch(motherNumberController.text)) {
      emit(StudentValidationError("Mother's number must be exactly 11 digits"));
      return;
    }

    if (selectedGender == null) {
      emit(StudentValidationError("Please select a gender"));
      return;
    }

    if (firstMonth == null ||
        secondMonth == null ||
        thirdMonth == null ||
        fourthMonth == null ||
        fifthMonth == null) {
      emit(StudentValidationError(
          "Please select payment status for all months"));
      return;
    }

    if (explainingNote == null || reviewNote == null) {
      emit(StudentValidationError(
          "Please select notes for explaining and reviewing"));
      return;
    }

    updatePaymentDates();

    Studentmodel submodel = Studentmodel(
      hisGroupsId: hisGroupsId,
      hisGroups: hisGroups,
      note: noteController.text.isEmpty ? "No note" : noteController.text,
      dateofadd: date!,
      name: name_controller.text,
      gender: selectedGender,
      grade: level,
      firstMonth: firstMonth,
      secondMonth: secondMonth,
      thirdMonth: thirdMonth,
      fourthMonth: fourthMonth,
      fifthMonth: fifthMonth,
      explainingNote: explainingNote,
      reviewNote: reviewNote,
      phoneNumber: studentNumberController.text,
      ParentPhone: motherNumberController.text,
      fatherPhone: "00000000000",
      dateOfFirstMonthPaid: dateOfFirstMonthPaid,
      dateOfSecondMonthPaid: dateOfSecondMonthPaid,
      dateOfThirdMonthPaid: dateOfThirdMonthPaid,
      dateOfFourthMonthPaid: dateOfFourthMonthPaid,
      dateOfFifthMonthPaid: dateOfFifthMonthPaid,
      dateOfExplainingNotePaid: dateOfExplainingNotePaid,
      dateOfReviewingNotePaid: dateOfReviewingNotePaid,
    );

    // Check if any payment/note is true
    bool hasPayment = reviewNote == true ||
        explainingNote == true ||
        firstMonth == true ||
        secondMonth == true ||
        thirdMonth == true ||
        fourthMonth == true ||
        fifthMonth == true;

    if (hasPayment) {
      // show dialog and wait until Save pressed
      await showPaymentChangeDialog(context, level, submodel);
    } else {
      // no payment -> just add directly
      try {
        emit(StudentLoading());
        await FirebaseFunctions.addStudentToCollection(level ?? "", submodel);
        emit(StudentAddedSuccess());
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homescreen()),
              (route) => false,
        );
      } catch (e) {
        emit(StudentAddedFailure(e.toString()));
      }
    }
  }

  void updatePaymentDates() {
    // Check if the payment statuses are true, and update the date accordingly.
    dateOfFirstMonthPaid = firstMonth == true ? date : null;
    dateOfSecondMonthPaid = secondMonth == true ? date : null;
    dateOfThirdMonthPaid = thirdMonth == true ? date : null;
    dateOfFourthMonthPaid = fourthMonth == true ? date : null;
    dateOfFifthMonthPaid = fifthMonth == true ? date : null;
    dateOfExplainingNotePaid = explainingNote == true ? date : null;
    dateOfReviewingNotePaid = reviewNote == true ? date : null;
  }

  Future<void> showPaymentChangeDialog(BuildContext context, level,
      Studentmodel submodel) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("Payment Changes Detected"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: totalAmountController,
                    decoration: const InputDecoration(
                      labelText: "Total Amount",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Total Amount cannot be empty';
                      }
                      return null;
                    },
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    totalAmount =
                        double.tryParse(totalAmountController.text) ?? 0.0;
                    description = descriptionController.text;

                    // ✅ Add student only after Save
                    try {
                      emit(StudentLoading());
                      String studentId =
                      await FirebaseFunctions.addStudentToCollection(
                          level ?? "", submodel);
                      emit(StudentAddedSuccess());


                      FirebaseFunctions.addInvoiceToBigInvoices(
                        date: date??"",
                        day: day??"",
                        amount: totalAmount,
                        description: description,
                        grade:level,
                        ParentPhone:motherNumberController.text,
                        phoneNumber:studentNumberController.text,
                        studentId:studentId,
                        studentName:name_controller.text,
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/HomeScreen',
                            (route) => false,
                      );
                    } catch (e) {
                      emit(StudentAddedFailure(e.toString()));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void updateGroup(BuildContext context, Magmo3amodel? result) {
    if (result != null) {
      bool groupExists = hisGroups.any((group) => group.id == result.id);

      if (!groupExists) {
        hisGroups.add(result);
        hisGroupsId.add(result.id); // Add the group ID to hisGroupsId list
        print('Added Group ID: ${result.id}');
        emit(StudentUpdated());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This Group already exists in the list.',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red, // Red background color
          ),
        );
      }

      print('His Groups: ${hisGroups.length}');
    }
  }

  void getCurrentDate() {
    DateTime now = DateTime.now();
    date = now.toIso8601String().substring(0, 10); // yyyy-mm-dd
    day = now.weekday == 1
        ? 'Monday'
        : now.weekday == 2
        ? 'Tuesday'
        : now.weekday == 3
        ? 'Wednesday'
        : now.weekday == 4
        ? 'Thursday'
        : now.weekday == 5
        ? 'Friday'
        : now.weekday == 6
        ? 'Saturday'
        : 'Sunday';
  }

  void setTheSelectedGenderByNull() {
    selectedGender = null;
    emit(StudentUpdated());
  }

  void changeValueOfGenderDropDown(value) {
    selectedGender = value as String;
    emit(StudentUpdated());
    print(selectedGender);
  }

  void changeFirstMonthValue(value) {
    firstMonth = value;
    emit(StudentUpdated());
    print(firstMonth);
  }

  void changeSecondMonthValue(value) {
    secondMonth = value;
    emit(StudentUpdated());
    print(secondMonth);
  }

  void changeThirdMonthValue(value) {
    thirdMonth = value;
    emit(StudentUpdated());
    print(thirdMonth);
  }

  void changeFourthMonthValue(value) {
    fourthMonth = value;
    emit(StudentUpdated());
    print(fourthMonth);
  }

  void changeFifthMonthValue(value) {
    fifthMonth = value;
    emit(StudentUpdated());
    print(fifthMonth);
  }

  void changeExplainingNoteValue(value) {
    explainingNote = value;
    emit(StudentUpdated());
    print(explainingNote);
  }

  void changeReviewNoteValue(value) {
    reviewNote = value;
    emit(StudentUpdated());
    print(reviewNote);
  }
}
