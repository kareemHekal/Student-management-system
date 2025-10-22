import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import '../../pages/AllStudentPage.dart';
import 'edit_student_state.dart';

class StudentEditCubit extends Cubit<StudentEditState> {
  final Studentmodel student;

  StudentEditCubit({required this.student}) : super(StudentEditInitial());

  final TextEditingController dismissibleAmountController =
      TextEditingController();
  final TextEditingController dismissibleDescController =
      TextEditingController();

  String? dateOfFirstMonthPaid;
  String? dateOfSecondMonthPaid;
  String? dateOfThirdMonthPaid;
  String? dateOfFourthMonthPaid;
  String? dateOfFifthMonthPaid;
  String? dateOfExplainingNotePaid;
  String? dateOfReviewingNotePaid;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController totalAmountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late String? date;
  late String? Day;
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
  List<Magmo3amodel>? hisGroups = [];
  List<String>? hisGroupsId = [];

  static StudentEditCubit get(context) => BlocProvider.of(context);

  initTheState() {
    getCurrentDate();

    hisGroups = student.hisGroups;
    hisGroupsId = student.hisGroupsId;
    dateOfFirstMonthPaid = student.dateOfFirstMonthPaid;
    dateOfSecondMonthPaid = student.dateOfSecondMonthPaid;
    dateOfThirdMonthPaid = student.dateOfThirdMonthPaid;
    dateOfFourthMonthPaid = student.dateOfFourthMonthPaid;
    dateOfFifthMonthPaid = student.dateOfFifthMonthPaid;
    dateOfExplainingNotePaid = student.dateOfExplainingNotePaid;
    dateOfReviewingNotePaid = student.dateOfReviewingNotePaid;

    noteController.text = student.note ?? "";
    name_controller.text = student.name ?? "";
    studentNumberController.text = student.phoneNumber ?? "";
    fatherNumberController.text = student.fatherPhone ?? "";
    motherNumberController.text = student.motherPhone ?? "";

    firstMonth = student.firstMonth;
    secondMonth = student.secondMonth;
    thirdMonth = student.thirdMonth;
    fourthMonth = student.fourthMonth;
    fifthMonth = student.fifthMonth;
    explainingNote = student.explainingNote;
    reviewNote = student.reviewNote;

    selectedGender = student.gender;
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
    Day = weekdays[now.weekday];
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

  void updateGroup(BuildContext context, Magmo3amodel? result) {
    if (result != null) {
      bool groupExists =
          hisGroups?.any((group) => group.id == result.id) ?? false;

      if (!groupExists) {
        hisGroups?.add(result);
        hisGroupsId?.add(result.id);
        emit(StudentUpdatedInEditPage());
      } else {
        emit(StudentValidationError("المجموعة هذه موجودة بالفعل في القائمة."));
      }
    }
  }

  Future<void> addInvoiceToBigInvoices({
    required String date,
    required String day,
    required String grade,
    required double amount,
    required String description,
  }) async {
    try {
      FirebaseFunctions.addInvoiceToBigInvoices(
        date: date,
        day: day,
        amount: amount,
        description: description,
        grade: student.grade ?? "",
        motherPhone: student.motherPhone ?? "",
        fatherPhone: student.fatherPhone ?? "",
        phoneNumber: student.phoneNumber ?? "",
        studentId: student.id,
        studentName: student.name ?? "",
      );
    } catch (e) {
      emit(StudentValidationError(e.toString()));
    }
  }

  Future<void> showPaymentDialog({
    required BuildContext context,
    required String grade,
    required String title,
    required bool dismissible,
    Studentmodel? studentModel,
    required Future<void> Function({
      required double amount,
      required String description,
      required String date,
      required String day,
    }) onSave,
  }) async {
    final _formKey = GlobalKey<FormState>();
    showDialog(
      barrierDismissible: dismissible,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: dismissible,
          child: AlertDialog(
            title: Text(title),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: dismissible
                          ? dismissibleAmountController
                          : totalAmountController,
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
                      controller: dismissible
                          ? dismissibleDescController
                          : descriptionController,
                      decoration: const InputDecoration(
                        labelText: "الوصف",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              if (dismissible)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final double totalAmount = double.tryParse(dismissible
                            ? dismissibleAmountController.text
                            : totalAmountController.text) ??
                        0.0;
                    final String description = dismissible
                        ? dismissibleDescController.text
                        : descriptionController.text;
                    final now = DateTime.now();
                    final date =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                    final day = [
                      "Sunday",
                      "Monday",
                      "Tuesday",
                      "Wednesday",
                      "Thursday",
                      "Friday",
                      "Saturday"
                    ][now.weekday % 7];

                    try {
                      emit(StudentEditLoading());
                      await onSave(
                        amount: totalAmount,
                        description: description,
                        date: date,
                        day: day,
                      );
                      emit(StudentEditSuccess());
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AllStudentsTab()),
                        (Route<dynamic> route) => false,
                      );
                    } catch (e) {
                      emit(StudentEditFailure(errorMessage: e.toString()));
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

  Future<void> EditStudent(BuildContext context, level) async {
    if (hisGroups == []) {
      emit(StudentValidationError("من فضلك اختر مجموعة واحدة على الأقل"));
      return;
    }

    if (name_controller.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل اسم الطالب"));
      return;
    }
    if (studentNumberController.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل رقم الطالب"));
      return;
    }

    if (!RegExp(r'^\d{11}$').hasMatch(studentNumberController.text)) {
      emit(StudentValidationError("رقم الطالب يجب أن يكون 11 رقمًا بالضبط"));
      return;
    }

    if (fatherNumberController.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل رقم الأب"));
      return;
    }

    if (!RegExp(r'^\d{11}$').hasMatch(fatherNumberController.text)) {
      emit(StudentValidationError("رقم الأب يجب أن يكون 11 رقمًا بالضبط"));
      return;
    }

    if (motherNumberController.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل رقم الأم"));
      return;
    }

    if (!RegExp(r'^\d{11}$').hasMatch(motherNumberController.text)) {
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
        fifthMonth == null ||
        fourthMonth == null) {
      emit(StudentValidationError("من فضلك اختر حالة الدفع لكل الشهور"));
      return;
    }
    if (explainingNote == null || reviewNote == null) {
      emit(StudentValidationError(
          "من فضلك اختر حالات الملاحظات للشرح والمراجعة"));
      return;
    }

    String? dateOfFirstMonthPaid = firstMonth != student.firstMonth
        ? firstMonth == true
            ? date
            : null
        : student.dateOfFirstMonthPaid;

    String? dateOfSecondMonthPaid = getPaymentDate(
        secondMonth, student.secondMonth, student.dateOfSecondMonthPaid, date);
    String? dateOfThirdMonthPaid = getPaymentDate(
        thirdMonth, student.thirdMonth, student.dateOfThirdMonthPaid, date);
    String? dateOfFourthMonthPaid = getPaymentDate(
        fourthMonth, student.fourthMonth, student.dateOfFourthMonthPaid, date);
    String? dateOfFifthMonthPaid = getPaymentDate(
        fifthMonth, student.fifthMonth, student.dateOfFifthMonthPaid, date);
    String? dateOfExplainingNotePaid = getPaymentDate(explainingNote,
        student.explainingNote, student.dateOfExplainingNotePaid, date);
    String? dateOfReviewingNotePaid = getPaymentDate(
        reviewNote, student.reviewNote, student.dateOfReviewingNotePaid, date);

    updatePaymentDates();

    Studentmodel submodel = Studentmodel(
      id: student.id,
      dateofadd: student.dateofadd,
      name: name_controller.text,
      gender: selectedGender,
      hisGroups: hisGroups,
      hisGroupsId: hisGroupsId,
      grade: level,
      firstMonth: firstMonth,
      secondMonth: secondMonth,
      thirdMonth: thirdMonth,
      note: noteController.text,
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

    bool isMonthOrNoteChanged =
        (student.firstMonth == false && firstMonth == true) ||
            (student.secondMonth == false && secondMonth == true) ||
            (student.thirdMonth == false && thirdMonth == true) ||
            (student.fourthMonth == false && fourthMonth == true) ||
            (student.fifthMonth == false && fifthMonth == true) ||
            (student.explainingNote == false && explainingNote == true) ||
            (student.reviewNote == false && reviewNote == true);

    if (isMonthOrNoteChanged) {
      await showPaymentDialog(
        context: context,
        grade: level,
        title: "تم الكشف عن تغييرات في الدفع",
        dismissible: false,
        onSave: ({
          required double amount,
          required String description,
          required String date,
          required String day,
        }) async {
          try {
            FirebaseFunctions.updateStudentInCollection(
              student.grade ?? "",
              student.id,
              submodel,
            );
            await addInvoiceToBigInvoices(
              date: date,
              day: day,
              grade: level,
              amount: amount,
              description: description,
            );
          } catch (e) {
            emit(StudentEditFailure(errorMessage: e.toString()));
          }
        },
      );
    } else {
      try {
        emit(StudentEditLoading());
        FirebaseFunctions.updateStudentInCollection(
          student.grade ?? "",
          student.id,
          submodel,
        );
        emit(StudentEditSuccess());
      } catch (e) {
        emit(StudentEditFailure(errorMessage: e.toString()));
      }
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم تعديل بيانات الطالب بنجاح!'),
      ),
    );
  }

  String? getPaymentDate(bool? currentValue, bool? previousValue,
      String? previousDate, String? date) {
    return currentValue != previousValue
        ? currentValue == true
            ? date
            : null
        : previousDate;
  }

  void setTheSelectedGenderByNull() {
    selectedGender = null;
    emit(StudentUpdatedInEditPage());
  }

  void changeValueOfGenderDropDown(value) {
    selectedGender = value as String;
    emit(StudentUpdatedInEditPage());
    print(selectedGender);
  }

  void changeFirstMonthValue(value) {
    firstMonth = value;
    emit(StudentUpdatedInEditPage());
    print(firstMonth);
  }

  void changeSecondMonthValue(value) {
    secondMonth = value;
    emit(StudentUpdatedInEditPage());
    print(secondMonth);
  }

  void changeThirdMonthValue(value) {
    thirdMonth = value;
    emit(StudentUpdatedInEditPage());
    print(thirdMonth);
  }

  void changeFourthMonthValue(value) {
    fourthMonth = value;
    emit(StudentUpdatedInEditPage());
    print(fourthMonth);
  }

  void changeFifthMonthValue(value) {
    fifthMonth = value;
    emit(StudentUpdatedInEditPage());
    print(fifthMonth);
  }

  void changeExplainingNoteValue(value) {
    explainingNote = value;
    emit(StudentUpdatedInEditPage());
    print(explainingNote);
  }

  void changeReviewNoteValue(value) {
    reviewNote = value;
    emit(StudentUpdatedInEditPage());
    print(reviewNote);
  }
}
