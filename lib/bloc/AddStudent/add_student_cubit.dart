import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/alert_dialogs/show_add_student_payment_dialog.dart';
import 'package:student_management_system/provider.dart';

import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Student_model.dart';
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

  Future<void> addStudent(BuildContext context, String? level) async {
    // 1. جلب بيانات المدرس الحالية من البروفايدر
    final teacherProvider =
        Provider.of<TeacherProvider>(context, listen: false);
    final teacher = teacherProvider.teacher;

    // 2. التحققات الأساسية (Validations)
    if (hisGroups.isEmpty) {
      emit(StudentValidationError("من فضلك اختر مجموعة واحدة على الأقل"));
      return;
    }
    if (name_controller.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل اسم الطالب"));
      return;
    }

    // ضبط أرقام الهاتف الافتراضية إذا كانت فارغة
    _sanitizePhoneNumbers();

    // 3. التحقق من صلاحية الاشتراك وسعة الطلاب
    if (teacher != null) {
      // أ- فحص انتهاء الاشتراك
      if (teacher.subscriptionEndTime.isBefore(DateTime.now())) {
        emit(StudentValidationError(
            "عفواً، اشتراكك منتهي. يرجى التجديد لتتمكن من إضافة طلاب"));
        return;
      }

      // ب- فحص المساحة المتاحة
      if (teacher.totalStudents >= teacher.subscriptionTotalStudents) {
        emit(StudentValidationError(
            "لقد وصلت للحد الأقصى للطلاب (${teacher.subscriptionTotalStudents}). يرجى ترقية الباقة لإضافة المزيد."));
        return;
      }
    } else {
      emit(StudentValidationError("خطأ: لم يتم العثور على بيانات المعلم"));
      return;
    }

    // 4. بناء موديل الطالب
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

      // 5. استدعاء الفايربيز (إضافة الطالب + زيادة العداد في Batch واحد)
      String studentId = await FirebaseFunctions.addStudentToCollection(
        level ?? "",
        submodel,
      );

      // 6. إضافة الفواتير المرتبطة بالطالب
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

      // 7. تحديث بيانات المدرس في البروفايدر محلياً ليعكس الرقم الجديد فوراً
      await teacherProvider.refreshTeacherData(); // افترضنا وجود دالة تحديث

      emit(StudentAddedSuccess());
      clearControllers();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Homescreen()),
        (route) => false,
      );
    } catch (e) {
      emit(StudentAddedFailure("حدث خطأ أثناء الإضافة: ${e.toString()}"));
    }
  }

// دالة مساعدة لتنظيف الأرقام
  void _sanitizePhoneNumbers() {
    if (studentNumberController.text.trim().isEmpty)
      studentNumberController.text = '00000000000';
    if (fatherNumberController.text.trim().isEmpty)
      fatherNumberController.text = '00000000000';
    if (motherNumberController.text.trim().isEmpty)
      motherNumberController.text = '00000000000';
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
      builder: (_) => addStudentPaidDialog(
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
