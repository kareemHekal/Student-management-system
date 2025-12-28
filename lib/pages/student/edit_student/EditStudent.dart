import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../../Alert dialogs/RemoveFromGroupsListDialog.dart';
import '../../../BottomSheets/student_actions_bottom_sheet.dart';
import '../../../bloc/Edit Student/edit_student_cubit.dart';
import '../../../bloc/Edit Student/edit_student_state.dart';
import '../../../cards/magmo3at/groupSmallCard.dart';
import '../../../cards/student/student_subscriptions_card.dart';
import '../../../firebase/firebase_functions.dart';
import '../../../models/Studentmodel.dart';
import '../../../models/grade_subscriptions_model.dart';
import '../../../models/student_paid_subscription.dart';
import '../../../theme/colors_app.dart';
import '../../../theme/text_style.dart';
import '../../all_absent_numbers.dart';
import '../add_student/Pick Groups Page.dart';

// --- الثوابت والأنماط المشتركة (Consts & Styles) -------------------------

const double _kAppbarHeight = 180;
const double _kSectionPadding = 10.0; // تم تقليل المسافة الأساسية
const double _kDividerThickness = 4;

// --- الشاشة الرئيسية (EditStudentScreen) --------------------------------

class EditStudentScreen extends StatefulWidget {
  final Studentmodel student;
  final String? grade;

  const EditStudentScreen(
      {required this.student, required this.grade, super.key});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late final FocusNode _nameFocus;
  late final FocusNode _studentNumberFocus;
  late final FocusNode _fatherNumberFocus;
  late final FocusNode _motherNumberFocus;
  final _formKey = GlobalKey<FormState>(); // مفتاح Form للتحقق من الصحة

  @override
  void initState() {
    super.initState();
    // 2. تهيئة مفاتيح التركيز في initState
    _nameFocus = FocusNode();
    _studentNumberFocus = FocusNode();
    _fatherNumberFocus = FocusNode();
    _motherNumberFocus = FocusNode();
  }

  @override
  void dispose() {
    // 3. التخلص من مفاتيح التركيز عند الخروج من الشاشة
    _nameFocus.dispose();
    _studentNumberFocus.dispose();
    _fatherNumberFocus.dispose();
    _motherNumberFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: BlocProvider(
        // تهيئة الـ Cubit وتمرير بيانات الطالب
        create: (context) =>
            StudentEditCubit(student: widget.student)..initTheState(),
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: LoaderOverlay(
            child: BlocConsumer<StudentEditCubit, StudentEditState>(
              listener: _blocListener,
              builder: (context, state) {
                if (state is StudentEditLoading) {
                  return const SizedBox.shrink();
                }
                return _buildBody(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- دوال المساعدة للـ Bloc (Bloc Helpers) --------------------------------
  void _blocListener(BuildContext context, StudentEditState state) {
    if (state is StudentEditLoading) {
      context.loaderOverlay.show();
    } else {
      context.loaderOverlay.hide();
    }
    if (state is StudentEditSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
            'تم تعديل بيانات الطالب بنجاح!', AppColors.statusPresent),
      );
    }
    if (state is StudentUpdatedInEditPage) {
      // إعادة بناء الـ widget عند تحديث حالة الطالب في الصفحة
      setState(() {});
    }
    if (state is StudentEditFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(state.errorMessage, AppColors.statusAbsent),
      );
    }
    if (state is StudentValidationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(state.errorMessage, AppColors.statusAbsent),
      );
    }
  }

  SnackBar _buildSnackBar(String content, Color color) {
    return SnackBar(
      content: Text(content),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
  }

  // --- دوال المساعدة للـ UI (UI Helpers) ------------------------------------

  // 1. بناء شريط التطبيق (AppBar)
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 10,
      shadowColor: Colors.yellow.shade700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            size: 30,
            color: AppColors.secondaryMain,
          ),
          onPressed: () {
            StudentActionsBottomSheet.show(
              context: context,
              student: widget.student,
            );
          },
        ),
      ],
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
      ),
      backgroundColor: AppColors.primaryMain,
      title: Image.asset(
        "assets/images/logo.png",
        height: 100,
        width: 90,
      ),
      toolbarHeight: _kAppbarHeight,
    );
  }

  // 2. بناء محتوى الصفحة (Body)
  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        // خلفية شفافة بشعار
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(
              child: Image.asset(
            "assets/images/logo.png",
            opacity: const AlwaysStoppedAnimation(0.1),
          )),
        ),
        // الطبقة التي تحمل المحتوى
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 17),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: _buildContentScrollable(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. بناء الجزء القابل للتمرير (Scrollable Content)
  Widget _buildContentScrollable(BuildContext context) {
    final cubit = StudentEditCubit.get(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleSection(),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم المجموعات
          const SizedBox(height: _kSectionPadding),
          _buildGroupsSelectionSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم حقول الإدخال
          const SizedBox(height: _kSectionPadding),
          _buildTextFormFieldsSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم اختيار الجنس
          const SizedBox(height: _kSectionPadding),
          _buildGenderSelectionSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم الدفعات والاشتراكات
          const SizedBox(height: _kSectionPadding),
          _buildPaymentsSection(context),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم الحضور والغياب
          const SizedBox(height: _kSectionPadding),
          _buildAbsencePresenceSection(context),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم الملاحظات
          const SizedBox(height: _kSectionPadding),
          _buildNotesSection(context, cubit),
          const SizedBox(height: 20), // مسافة أكبر قبل الزر

          // زر الحفظ
          _buildSaveButton(context, cubit),
          const SizedBox(height: 50), // مسافة نهاية الصفحة
        ],
      ),
    );
  }

  // 4. بناء عنصر فاصل (Divider)
  Widget _buildDivider() {
    return const Divider(
      color: AppColors.secondaryMain,
      thickness: _kDividerThickness,
    );
  }

  // 5. بناء قسم العنوان
  Widget _buildTitleSection() {
    return Text(
      'تعديل بيانات الطالب',
      style: AppTextStyles.customText(
        fontSize: 30,
        color: AppColors.primaryMain,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.start,
    );
  }

  // 6. بناء قسم اختيار المجموعات
  Widget _buildGroupsSelectionSection(
      BuildContext context, StudentEditCubit cubit) {
    final bool isGroupsEmpty =
        cubit.hisGroups == null || cubit.hisGroups!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
            child: Text(
                "المجموعات المشترك بها : ${cubit.hisGroups?.length ?? 0} ",
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        // تم إلغاء الـ SizedBox ذو الارتفاع الثابت واستبداله بـ shrinkWrap
        if (isGroupsEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                "لم تقم باختيار أي مجموعة بعد",
                style: AppTextStyles.customText(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            shrinkWrap: true,
            // تجعل القائمة تأخذ مساحة عناصرها فقط
            physics: const NeverScrollableScrollPhysics(),
            // تمنع تضارب السكرول
            itemCount: cubit.hisGroups!.length,
            itemBuilder: (context, index) {
              final magmo3aModel = cubit.hisGroups![index];
              return _buildGroupCard(context, cubit, magmo3aModel, index);
            },
          ),
        const SizedBox(height: 10),
        _buildAddGroupButton(context, cubit),
      ],
    );
  }
  // 6.1. كارت المجموعة
  Widget _buildGroupCard(BuildContext context, StudentEditCubit cubit,
      dynamic magmo3aModel, int index) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return RemoveFromGroupsListDialog(
              title: "حذف المجموعة",
              content: "هل أنت متأكد أنك تريد إزالة هذه المجموعة؟",
              onConfirm: () async {
                cubit.hisGroups!.removeAt(index);
                cubit.hisGroupsId!.removeAt(index);
                // استخدام setState لإعادة بناء الـ widget الخاص بقائمة المجموعات
                // بدلاً من انتظار حالة الـ cubit
                setState(() {});
              },
            );
          },
        );
      },
      child: Groupsmallcard(magmo3aModel: magmo3aModel),
    );
  }

  // 6.2. زر إضافة مجموعة
  Widget _buildAddGroupButton(BuildContext context, StudentEditCubit cubit) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: const BorderSide(color: AppColors.secondaryMain, width: 1),
        foregroundColor: AppColors.secondaryMain,
        backgroundColor: AppColors.primaryMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChoosedaysToAttend(level: widget.grade),
          ),
        ).then((result) {
          if (result != null) {
            cubit.updateGroup(context, result);
          }
        });
      },
      child: Text("إضافة مجموعة",
          style: AppTextStyles.customText(
              color: AppColors.textOnDark, fontWeight: FontWeight.bold)),
    );
  }

  // 7. بناء قسم حقول إدخال النص (TextFormFields)
  Widget _buildTextFormFieldsSection(
      BuildContext context, StudentEditCubit cubit) {
    return Form(
      key: _formKey, // ربط مفتاح التحقق من الصحة
      child: Column(
        children: [
          // 1. اسم الطالب (Next)
          _buildCustomTextFormField(
            controller: cubit.name_controller,
            label: "اسم الطالب",
            focusNode: _nameFocus,
            inputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_studentNumberFocus),
          ),
          const SizedBox(height: _kSectionPadding),

          // 2. رقم الطالب (Next)
          _buildCustomTextFormField(
            controller: cubit.studentNumberController,
            label: "رقم الطالب",
            keyboardType: TextInputType.number,
            focusNode: _studentNumberFocus,
            inputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_fatherNumberFocus),
          ),
          const SizedBox(height: _kSectionPadding),

          // 3. رقم ولي الأمر (Next)
          _buildCustomTextFormField(
            controller: cubit.fatherNumberController,
            label: "رقم ولي الأمر",
            keyboardType: TextInputType.phone,
            focusNode: _fatherNumberFocus,
            inputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_motherNumberFocus),
          ),
          const SizedBox(height: _kSectionPadding),

          // 4. رقم الأم (Done) - وهو الحقل الأخير في هذا القسم
          _buildCustomTextFormField(
            controller: cubit.motherNumberController,
            label: "رقم الأم",
            keyboardType: TextInputType.phone,
            focusNode: _motherNumberFocus,
            inputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              // يمكن هنا تنفيذ عملية الحفظ أو إخفاء لوحة المفاتيح
              FocusScope.of(context).unfocus();
            },
          ),
        ],
      ),
    );
  }

  // 7.1. عنصر حقل إدخال النص المخصص (InputDecoration)
  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.customText(
          fontSize: 18, color: AppColors.textSecondary),
      hintStyle: AppTextStyles.customText(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primaryMain, width: 1.5),
        borderRadius: BorderRadius.circular(15.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            const BorderSide(color: AppColors.secondaryMain, width: 2.5),
        borderRadius: BorderRadius.circular(15.0),
      ),
    );
  }

  // 7.2. بناء حقل إدخال النص الفردي
  Widget _buildCustomTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    required FocusNode focusNode, // إضافة FocusNode
    required TextInputAction inputAction, // إضافة TextInputAction
    void Function(String)?
        onFieldSubmitted, // لإضافة دالة الانتقال عند الضغط على "Next"
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      // تعيين FocusNode
      textInputAction: inputAction,
      // تعيين زر لوحة المفاتيح (Next/Done)
      onFieldSubmitted: onFieldSubmitted,
      // دالة التنفيذ عند الضغط على زر الإدخال
      style: AppTextStyles.customText(color: AppColors.textPrimary),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'من فضلك أدخل $label';
        }
        return null;
      },
      decoration: _getInputDecoration(label),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }

  // 8. بناء قسم اختيار الجنس (MaleOrFemalePart)
  Widget _buildGenderSelectionSection(
      BuildContext context, StudentEditCubit cubit) {
    // تم إزالة الـ Padding الخارجي ونقل المسافة إلى العمود الرئيسي
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGenderDropdown(cubit),
        const SizedBox(height: _kSectionPadding),
        _buildSelectedGenderChip(cubit),
      ],
    );
  }

  // 8.1. قائمة اختيار الجنس المنسدلة
  Widget _buildGenderDropdown(StudentEditCubit cubit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryMain, width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: AppColors.white,
          value: cubit.selectedGender ?? "ذكر",
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: "ذكر",
              child:
                  Text("ذكر", style: TextStyle(color: AppColors.primaryMain)),
            ),
            DropdownMenuItem(
              value: "أنثى",
              child:
                  Text("أنثى", style: TextStyle(color: AppColors.primaryMain)),
            ),
          ],
          onChanged: (value) {
            cubit.changeValueOfGenderDropDown(value);
          },
          elevation: 4,
          // **تم التعديل هنا لتغيير لون النص المختار**
          style: AppTextStyles.customText(color: AppColors.primaryDark),
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.secondaryMain, size: 30),
        ),
      ),
    );
  }

  // 8.2. عرض الشريحة (Chip) للجنس المختار
  Widget _buildSelectedGenderChip(StudentEditCubit cubit) {
    return cubit.selectedGender != null
        ? Wrap(
            direction: Axis.horizontal,
            spacing: 8,
            children: [
              Chip(
                backgroundColor: AppColors.primaryMain,
                label: Text(cubit.selectedGender!,
                    style:
                        AppTextStyles.customText(color: AppColors.textOnDark)),
                deleteIcon: const Icon(Icons.cancel,
                    size: 20, color: AppColors.secondaryMain),
                shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.secondaryMain)),
                onDeleted: () {
                  cubit.setTheSelectedGenderByNull();
                },
              ),
            ],
          )
        : Center(
            child: Text("اختر الجنس",
                style:
                    AppTextStyles.customText(color: AppColors.textSecondary)),
          );
  }

// 9. بناء قسم الدفعات والاشتراكات
  Widget _buildPaymentsSection(BuildContext context) {
    final cubit = StudentEditCubit.get(context);
    return StreamBuilder<GradeSubscriptionsModel?>(
      stream: FirebaseFunctions.getGradeSubscriptionsStream(widget.grade ?? ""),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text(
              'لا توجد اشتراكات لهذا الصف حالياً',
              style: AppTextStyles.customText(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          );
        }

        final gradeSubs = snapshot.data!;
        final subscriptions = gradeSubs.subscriptions;
        final studentPaidSubscriptions = cubit.studentPaidSubscriptions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة الاشتراكات (${subscriptions.length})',
              textAlign: TextAlign.center,
              style: AppTextStyles.customText(
                color: AppColors.primaryMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // تم إلغاء الـ SizedBox واستخدام الـ ListView بشكل مباشر مع physics مناسبة
            if (subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    ' لا يوجد اشتراكات حتى الأن ',
                    style: AppTextStyles.customText(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  final paidSub = studentPaidSubscriptions?.firstWhere(
                    (s) => s.subscriptionId == sub.id,
                    orElse: () => StudentPaidSubscriptions(
                      description: "",
                      subscriptionId: sub.id,
                      paidAmount: 0,
                    ),
                  );

                  return GestureDetector(
                    onTap: () {
                      cubit.changePayment(
                          paidSub!, sub.subscriptionAmount, context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: StudentSubscriptionsCard(
                        studentPaidSubscription: paidSub,
                        subscriptionFee: sub,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
  // 10. بناء قسم الحضور والغياب
  Widget _buildAbsencePresenceSection(BuildContext context) {
    // تم إزالة الـ Padding الخارجي
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCountInfo(
            "أيام الحضور", widget.student.countingAttendedDays?.length,
            color: AppColors.statusPresent),
        _buildCountInfo(
            "أيام الغياب", widget.student.countingAbsentDays?.length,
            color: AppColors.statusAbsent),
        _buildCalendarButton(context),
      ],
    );
  }

  // 10.1. عرض عدد الحضور/الغياب
  Widget _buildCountInfo(String label, int? number, {required Color color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.customText(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            (number ?? 0).toString(),
            style: AppTextStyles.customText(fontSize: 18, color: color),
          ),
        ),
      ],
    );
  }

  // 10.2. زر عرض تفاصيل التقويم (AbsencesListPage)
  Widget _buildCalendarButton(BuildContext context) {
    return Column(
      children: [
        Text(
          "التقويم",
          style: AppTextStyles.customText(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (
                  context,
                ) =>
                    AbsencesListPage(
                  studentName: widget.student.name ?? "",
                  currentAbsentDays: widget.student.countingAbsentDays ?? [],
                  currentAttendedDays:
                      widget.student.countingAttendedDays ?? [],
                  absences: widget.student.absencesNumbers ?? [],
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.calendar_month,
            size: 30,
            color: AppColors.secondaryMain,
          ),
        ),
      ],
    );
  }

  // 11. بناء قسم الملاحظات (NotesPart)
  Widget _buildNotesSection(BuildContext context, StudentEditCubit cubit) {
    // تم إزالة الـ Padding الخارجي
    return TextFormField(
      controller: cubit.noteController,
      maxLines: 3,
      style: AppTextStyles.customText(color: AppColors.textPrimary),
      decoration: _getInputDecoration("إضافة ملاحظة").copyWith(
        hintText: 'اكتب ملاحظتك هنا...',
      ),
    );
  }

  // 12. بناء زر الحفظ/التعديل
  Widget _buildSaveButton(BuildContext context, StudentEditCubit cubit) {
    // تم إزالة الـ Padding الخارجي
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.secondaryMain,
              backgroundColor: AppColors.primaryMain,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
            ),
            onPressed: () async {
              await cubit.EditStudent(context, widget.grade);
            },
            child: Text("تعديل وحفظ البيانات",
                style: AppTextStyles.customText(
                    color: AppColors.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}