import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import 'add_student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  StudentCubit() : super(StudentInitial());

  late double totalAmount;
  late String description;
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
  TextEditingController fatherNumberController = TextEditingController();
  TextEditingController motherNumberController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  List<Magmo3amodel> hisGroups = [];
  List<String> hisGroupsId = [];

  static StudentCubit get(context) => BlocProvider.of(context);

  initTheState() {
    hisGroups = [];
    getCurrentDate();
  }

  Future<void> addStudent(BuildContext context, level) async {
    if (hisGroups.isEmpty) {
      emit(StudentValidationError("من فضلك اختر مجموعة واحدة على الأقل"));
      return;
    }

    if (name_controller.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل اسم الطالب"));
      return;
    }
    if (studentNumberController.text.trim().isEmpty) {
      studentNumberController.text = '00000000000';
    } else if (!RegExp(r'^\d{11}$').hasMatch(studentNumberController.text)) {
      emit(StudentValidationError("رقم الطالب يجب أن يكون 11 رقمًا بالضبط"));
      return;
    }

    if (fatherNumberController.text.trim().isEmpty) {
      fatherNumberController.text = '00000000000';
    } else if (!RegExp(r'^\d{11}$').hasMatch(fatherNumberController.text)) {
      emit(StudentValidationError("رقم الأب يجب أن يكون 11 رقمًا بالضبط"));
      return;
    }

    if (motherNumberController.text.trim().isEmpty) {
      motherNumberController.text = '00000000000';
    } else if (!RegExp(r'^\d{11}$').hasMatch(motherNumberController.text)) {
      emit(StudentValidationError("رقم الأم يجب أن يكون 11 رقمًا بالضبط"));
      return;
    }

    if (selectedGender == null) {
      emit(StudentValidationError("من فضلك اختر النوع"));
      return;
    }

    if (firstMonth == null ||
        secondMonth == null ||
        thirdMonth == null ||
        fourthMonth == null ||
        fifthMonth == null) {
      emit(StudentValidationError("من فضلك اختر حالة الدفع لكل الشهور"));
      return;
    }

    if (explainingNote == null || reviewNote == null) {
      emit(StudentValidationError(
          "من فضلك اختر حالات الملاحظات للشرح والمراجعة"));
      return;
    }

    updatePaymentDates();

    Studentmodel submodel = Studentmodel(
      hisGroupsId: hisGroupsId,
      hisGroups: hisGroups,
      note: noteController.text.isEmpty ? "بدون ملاحظة" : noteController.text,
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
      motherPhone: motherNumberController.text,
      fatherPhone: fatherNumberController.text,
      dateOfFirstMonthPaid: dateOfFirstMonthPaid,
      dateOfSecondMonthPaid: dateOfSecondMonthPaid,
      dateOfThirdMonthPaid: dateOfThirdMonthPaid,
      dateOfFourthMonthPaid: dateOfFourthMonthPaid,
      dateOfFifthMonthPaid: dateOfFifthMonthPaid,
      dateOfExplainingNotePaid: dateOfExplainingNotePaid,
      dateOfReviewingNotePaid: dateOfReviewingNotePaid,
    );

    bool hasPayment = reviewNote == true ||
        explainingNote == true ||
        firstMonth == true ||
        secondMonth == true ||
        thirdMonth == true ||
        fourthMonth == true ||
        fifthMonth == true;

    if (hasPayment) {
      await showPaymentChangeDialog(context, level, submodel);
    } else {
      try {
        emit(StudentLoading());
        await FirebaseFunctions.addStudentToCollection(level ?? "", submodel);
        emit(StudentAddedSuccess());
        clearControllers();
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
    dateOfFirstMonthPaid = firstMonth == true ? date : null;
    dateOfSecondMonthPaid = secondMonth == true ? date : null;
    dateOfThirdMonthPaid = thirdMonth == true ? date : null;
    dateOfFourthMonthPaid = fourthMonth == true ? date : null;
    dateOfFifthMonthPaid = fifthMonth == true ? date : null;
    dateOfExplainingNotePaid = explainingNote == true ? date : null;
    dateOfReviewingNotePaid = reviewNote == true ? date : null;
  }

  Future<void> showPaymentChangeDialog(
    BuildContext context,
    level,
    Studentmodel submodel,
  ) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("تم الكشف عن تغييرات في الدفع"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: totalAmountController,
                    decoration: const InputDecoration(
                      labelText: "المبلغ الإجمالي",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'المبلغ الإجمالي لا يمكن أن يكون فارغًا';
                      }
                      return null;
                    },
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "الوصف"),
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

                    try {
                      emit(StudentLoading());
                      String studentId =
                      await FirebaseFunctions.addStudentToCollection(
                        level ?? "",
                        submodel,
                      );
                      emit(StudentAddedSuccess());

                      FirebaseFunctions.addInvoiceToBigInvoices(
                        date: date ?? "",
                        day: day ?? "",
                        amount: totalAmount,
                        description: description,
                        grade: level,
                        fatherPhone: fatherNumberController.text,
                        motherPhone: motherNumberController.text,
                        phoneNumber: studentNumberController.text,
                        studentId: studentId,
                        studentName: name_controller.text,
                      );
                      clearControllers();
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
                child: const Text('حفظ'),
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
        hisGroupsId.add(result.id);
        emit(StudentUpdated());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'المجموعة هذه موجودة بالفعل في القائمة.',
              style: TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void getCurrentDate() {
    DateTime now = DateTime.now();
    const Map<int, String> weekdays = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    date = now.toIso8601String().substring(0, 10);
    day = weekdays[now.weekday];
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

  void clearControllers() {
    name_controller.clear();
    studentNumberController.clear();
    fatherNumberController.clear();
    motherNumberController.clear();
    noteController.clear();
    totalAmountController.clear();
    descriptionController.clear();
    selectedGender = null;
    firstMonth = secondMonth = thirdMonth = fourthMonth = fifthMonth = null;
    explainingNote = reviewNote = null;
    hisGroups.clear();
    hisGroupsId.clear();
    emit(StudentInitial());
  }
}
