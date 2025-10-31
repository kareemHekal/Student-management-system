import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Alert dialogs/edit_on_payment.dart';
import '../../firebase/firebase_functions.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import '../../models/student_paid_subscription.dart';
import 'edit_student_state.dart';

class StudentEditCubit extends Cubit<StudentEditState> {
  final Studentmodel student;

  StudentEditCubit({required this.student}) : super(StudentEditInitial());

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String? date;
  late String? day;
  String? selectedGender;
  TextEditingController name_controller = TextEditingController();
  TextEditingController studentNumberController = TextEditingController();
  TextEditingController fatherNumberController = TextEditingController();
  TextEditingController motherNumberController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  List<Magmo3amodel>? hisGroups = [];
  List<StudentPaidSubscriptions>? studentPaidSubscriptions = [];
  List<StudentPaidSubscriptions>? newPaidSubscriptions = [];
  List<String>? hisGroupsId = [];

  static StudentEditCubit get(context) => BlocProvider.of(context);

  initTheState() {
    getCurrentDate();
    hisGroups = student.hisGroups;
    hisGroupsId = student.hisGroupsId;
    studentPaidSubscriptions = student.studentPaidSubscriptions;
    noteController.text = student.note ?? "";
    name_controller.text = student.name ?? "";
    studentNumberController.text = student.phoneNumber ?? "";
    fatherNumberController.text = student.fatherPhone ?? "";
    motherNumberController.text = student.motherPhone ?? "";
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
    day = weekdays[now.weekday];
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

  Future<void> addInvoiceToBigInvoices() async {
    try {
      for (final paidSub in newPaidSubscriptions ?? []) {
        await FirebaseFunctions.addInvoiceToBigInvoices(
          subscriptionFeeID: paidSub.subscriptionId ?? "",
          date: date ?? "",
          day: day ?? "",
          amount: paidSub.paidAmount ?? 0,
          description: paidSub.description ?? "",
          grade: student.grade ?? "",
          phoneNumber: studentNumberController.text,
          motherPhone: motherNumberController.text,
          fatherPhone: fatherNumberController.text,
          studentId: student.id,
          studentName: name_controller.text,
        );
      }
    } catch (e) {
      emit(StudentValidationError(e.toString()));
    }
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

    Studentmodel submodel = Studentmodel(
      id: student.id,
      dateofadd: student.dateofadd,
      name: name_controller.text,
      gender: selectedGender,
      hisGroups: hisGroups,
      studentExamsGrades: student.studentExamsGrades,
      absencesNumbers: student.absencesNumbers,
      countingAbsentDays: student.countingAbsentDays,
      countingAttendedDays: student.countingAttendedDays,
      studentPaidSubscriptions: studentPaidSubscriptions,
      hisGroupsId: hisGroupsId,
      grade: level,
      note: noteController.text,
      phoneNumber: studentNumberController.text,
      motherPhone: motherNumberController.text,
      fatherPhone: fatherNumberController.text,
    );

    try {
      emit(StudentEditLoading());
      FirebaseFunctions.updateStudentInCollection(
        student.grade ?? "",
        student.id,
        submodel,
      );

      addInvoiceToBigInvoices();

      emit(StudentEditSuccess());
    } catch (e) {
      emit(StudentEditFailure(errorMessage: e.toString()));
    }
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('تم تعديل بيانات الطالب بنجاح!'),
      ),
    );
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

  void changePayment(StudentPaidSubscriptions studentPaidSubscription,
      double fullPrice, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditPaidDialog(
        paidAmount: studentPaidSubscription.paidAmount,
        fullPrice: fullPrice,
        onSave: (newAmount, allAmount, comingDescription) {
          // Check if this subscriptionId already exists
          int index = studentPaidSubscriptions?.indexWhere((sub) =>
                  sub.subscriptionId ==
                  studentPaidSubscription.subscriptionId) ??
              -1;

          if (index != -1) {
            // Overwrite the existing entry
            studentPaidSubscriptions?[index] = StudentPaidSubscriptions(
                description: comingDescription,
                paidAmount: allAmount,
                subscriptionId: studentPaidSubscription.subscriptionId);
          } else {
            // Add new entry
            studentPaidSubscriptions?.add(StudentPaidSubscriptions(
                description: comingDescription,
                paidAmount: allAmount,
                subscriptionId: studentPaidSubscription.subscriptionId));
          }
          newPaidSubscriptions?.add(StudentPaidSubscriptions(
              description: comingDescription,
              paidAmount: newAmount,
              subscriptionId: studentPaidSubscription.subscriptionId));
          emit(StudentEditInitial());
        },
      ),
    );
  }
}
