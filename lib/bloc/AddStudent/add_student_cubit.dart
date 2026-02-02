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
    await teacherProvider.refreshTeacherData();
    final teacher = teacherProvider.teacher;

    // 2. التحققات الأساسية
    if (hisGroups.isEmpty) {
      emit(StudentValidationError("من فضلك اختر مجموعة واحدة على الأقل"));
      return;
    }
    if (selectedGender == "" || selectedGender == null) {
      emit(StudentValidationError("من فضلك اختر جنس الطالب "));
      return;
    }
    if (name_controller.text.isEmpty) {
      emit(StudentValidationError("من فضلك أدخل اسم الطالب"));
      return;
    }

    _sanitizePhoneNumbers();

    // 3. التحقق الذكي من الاشتراك (القلب الجديد للسيستم)
    if (teacher != null) {
      // أ- فحص انتهاء الاشتراك الأساسي (عشان يقدر يفتح التطبيق أصلاً)
      if (teacher.subscriptionEndTime.isBefore(DateTime.now()) ||
          teacher.isActive == false) {
        emit(StudentValidationError(
            "عفواً، اشتراكك منتهي. يرجى التجديد لتتمكن من إضافة طلاب"));
        return;
      }

      // ب- فحص المساحة المتاحة (أساسي + بوست)
      // لاحظ استخدام totalAllowedStudents بدلاً من المتغير القديم
      int allowed = await teacher.getTotalAllowedStudents();
      int current = teacher.currentStudentCount;

      if (current >= allowed) {
        emit(StudentValidationError(
            "لقد وصلت للحد الأقصى المتاح لك حالياً ($allowed طالب). يمكنك شراء باقة Boost لزيادة السعة فوراً."));
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

      // 5. استدعاء الفايربيز
      // ملاحظة هامة: دالة addStudentToCollection لازم تكون بتستخدم Transaction أو Batch
      // عشان تزود عداد الـ currentStudentCount في ملف المدرس بالتزامن مع إضافة الطالب
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

      // 7. تحديث البروفايدر (تأكد أن refreshTeacherData يجلب البيانات الجديدة من Firestore)
      await teacherProvider.refreshTeacherData();

      emit(StudentAddedSuccess());
      clearControllers();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homescreen()),
          (route) => false,
        );
      }
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
