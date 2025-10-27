import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Alert dialogs/show_add_student_payment_dialog.dart';
import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import '../../models/student_paid_subscription.dart';
import 'add_student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  StudentCubit() : super(StudentInitial());
  List<StudentPaidSubscriptions>? studentPaidSubscriptions = [];
  late String? date;
  late String? day;
  String? selectedGender;
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

    Studentmodel submodel = Studentmodel(
      hisGroupsId: hisGroupsId,
      studentPaidSubscriptions: studentPaidSubscriptions,
      hisGroups: hisGroups,
      note: noteController.text.isEmpty ? "بدون ملاحظة" : noteController.text,
      dateofadd: date ?? "",
      name: name_controller.text,
      gender: selectedGender,
      grade: level,
      phoneNumber: studentNumberController.text,
      motherPhone: motherNumberController.text,
      fatherPhone: fatherNumberController.text,
    );

    try {
      emit(StudentLoading());
      String studentId = await FirebaseFunctions.addStudentToCollection(
        level ?? "",
        submodel,
      );

      emit(StudentAddedSuccess());

      for (final paidSub in studentPaidSubscriptions ?? []) {
        await FirebaseFunctions.addInvoiceToBigInvoices(
          subscriptionFeeID: paidSub.subscriptionId ?? "",
          date: date ?? "",
          day: day ?? "",
          amount: paidSub.paidAmount ?? 0,
          description: paidSub.description ?? "",
          grade: level ?? "",
          phoneNumber: studentNumberController.text,
          motherPhone: motherNumberController.text,
          fatherPhone: fatherNumberController.text,
          studentId: studentId,
          studentName: name_controller.text,
        );
      }

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

  void clearControllers() {
    name_controller.clear();
    studentNumberController.clear();
    fatherNumberController.clear();
    motherNumberController.clear();
    noteController.clear();
    selectedGender = null;
    hisGroups.clear();
    hisGroupsId.clear();
    emit(StudentInitial());
  }

  void changePayment(StudentPaidSubscriptions studentPaidSubscription,
      double fullPrice, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PaidDialog(
        paidAmount: studentPaidSubscription.paidAmount,
        fullPrice: fullPrice,
        onSave: (editedAmount, comingDescription) {
          // Check if this subscriptionId already exists
          int index = studentPaidSubscriptions?.indexWhere((sub) =>
                  sub.subscriptionId ==
                  studentPaidSubscription.subscriptionId) ??
              -1;

          if (index != -1) {
            // Overwrite the existing entry
            studentPaidSubscriptions?[index] = StudentPaidSubscriptions(
                description: comingDescription,
                paidAmount: editedAmount,
                subscriptionId: studentPaidSubscription.subscriptionId);
          } else {
            // Add new entry
            studentPaidSubscriptions?.add(StudentPaidSubscriptions(
                paidAmount: editedAmount,
                description: comingDescription,
                subscriptionId: studentPaidSubscription.subscriptionId));
          }

          emit(StudentUpdated());
        },
      ),
    );
  }
}
