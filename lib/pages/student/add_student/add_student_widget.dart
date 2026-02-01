import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:student_management_system/alert_dialogs/RemoveFromGroupsListDialog.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../../../bloc/AddStudent/add_student_cubit.dart';
import '../../../bloc/AddStudent/add_student_state.dart';
import '../../../cards/magmo3at/groupSmallCard.dart';
import '../../../cards/student/student_subscriptions_card.dart';
import '../../../firebase/firebase_functions.dart';
import '../../../models/grade_subscriptions_model.dart';
import '../../../models/student_paid_subscription.dart';
import '../../../theme/colors_app.dart';
import '../../../theme/text_style.dart';
import 'Pick Groups Page.dart';

const double _kSectionPadding = 10.0; // مسافة موحدة بين الأقسام
const double _kDividerThickness = 4;

// --- الشاشة الرئيسية (AddStudentScreen) --------------------------------

class AddStudentScreen extends StatefulWidget {
  final String? grade;

  const AddStudentScreen({this.grade, super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  // 1. تعريف مفاتيح التركيز لنموذج الإدخال
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
    return BlocProvider(
      create: (context) => StudentCubit()..initTheState(),
      child: Scaffold(
        body: LoaderOverlay(
          child: BlocConsumer<StudentCubit, StudentState>(
            listener: _blocListener,
            builder: (context, state) {
              if (state is StudentLoading) {
                // إظهار مؤشر التحميل عبر Overlay
                return const SizedBox.shrink();
              }
              return _buildBody(context); // بناء جسم الصفحة
            },
          ),
        ),
      ),
    );
  }

  // --- دوال المساعدة للـ Bloc (Bloc Helpers) --------------------------------
  void _blocListener(BuildContext context, StudentState state) {
    if (state is StudentLoading) {
      context.loaderOverlay.show();
    } else {
      context.loaderOverlay.hide();
    }
    if (state is StudentAddedSuccess) {
      AppSnackBars.showSuccess(context, 'تم إضافة الطالب بنجاح!');
    }
    if (state is StudentUpdated) {
      setState(() {});
    }
    if (state is StudentAddedFailure) {
      AppSnackBars.showError(context, state.errorMessage);
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

  // 2. بناء محتوى الصفحة (Body)
  Widget _buildBody(BuildContext context) {
    // تم استخدام Padding بسيط لل Body الخارجي
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
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
          child: _buildContentScrollable(context),
        ),
      ),
    );
  }

  // 3. بناء الجزء القابل للتمرير (Scrollable Content)
  Widget _buildContentScrollable(BuildContext context) {
    final cubit = StudentCubit.get(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // الـ Padding الرئيسي حول المحتوى لتقليل المسافات بشكل عام
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleSection(), // "أضف طلابك"
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),
          const SizedBox(height: _kSectionPadding),
          _buildTextFormFieldsSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),
          // قسم اختيار الجنس
          const SizedBox(height: _kSectionPadding),
          _buildGenderSelectionSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),

          // قسم المجموعات
          const SizedBox(height: _kSectionPadding),
          _buildGroupsSelectionSection(context, cubit),
          const SizedBox(height: _kSectionPadding),
          _buildDivider(),
          // قسم الدفعات والاشتراكات
          const SizedBox(height: _kSectionPadding),
          _buildPaymentsSection(context),
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
      'أضف طلابك',
      style: AppTextStyles.customText(
        fontSize: 30,
        color: AppColors.primaryMain,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.start,
    );
  }

  // 6. بناء قسم اختيار المجموعات (مع الارتفاع الديناميكي)
  Widget _buildGroupsSelectionSection(
      BuildContext context, StudentCubit cubit) {
    final bool isGroupsEmpty = cubit.hisGroups.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "المجموعات المشترك بها : ${cubit.hisGroups.length ?? 0} ",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // بدلاً من SizedBox بارتفاع ثابت، نستخدم شرطاً بسيطاً
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
            // تجعل القائمة تأخذ مساحة العناصر فقط
            physics: const NeverScrollableScrollPhysics(),
            // تمنع التمرير الداخلي المنفصل
            itemCount: cubit.hisGroups.length,
            itemBuilder: (context, index) {
              final magmo3aModel = cubit.hisGroups[index];
              return _buildGroupCard(context, cubit, magmo3aModel, index);
            },
          ),
        const SizedBox(height: 10),
        _buildAddGroupButton(context, cubit),
      ],
    );
  }
  // 6.1. كارت المجموعة
  Widget _buildGroupCard(BuildContext context, StudentCubit cubit,
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
                cubit.hisGroups.removeAt(index);
                cubit.hisGroupsId.removeAt(index);
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
  Widget _buildAddGroupButton(BuildContext context, StudentCubit cubit) {
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
  Widget _buildTextFormFieldsSection(BuildContext context, StudentCubit cubit) {
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
            keyboardType: TextInputType.phone,
            focusNode: _studentNumberFocus,
            inputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_fatherNumberFocus),
          ),

          // onFieldSubmitted: (_) =>
          //    FocusScope.of(context).requestFocus(_fatherNumberFocus),
          //

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
            label: "رقم ولي الأمر 2",
            keyboardType: TextInputType.phone,
            focusNode: _motherNumberFocus,
            inputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
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
    required FocusNode focusNode,
    required TextInputAction inputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: inputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.customText(color: AppColors.textPrimary),
      validator: (value) {
        // **التعديل الجديد:**
        // إذا كان نوع لوحة المفاتيح هو رقم هاتف، فالسماح بقيمة فارغة أو null.
        if (keyboardType == TextInputType.phone) {
          return null; // لا تقم بالتحقق من الصحة (Validation)
        }

        // التحقق القياسي للحقول الأخرى (مثل الاسم ورقم الطالب)
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
      BuildContext context, StudentCubit cubit) {
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
  Widget _buildGenderDropdown(StudentCubit cubit) {
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
          style: AppTextStyles.customText(color: AppColors.primaryDark),
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.secondaryMain, size: 30),
        ),
      ),
    );
  }

  // 8.2. عرض الشريحة (Chip) للجنس المختار
  Widget _buildSelectedGenderChip(StudentCubit cubit) {
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

  // 9. بناء قسم الدفعات والاشتراكات (مع الارتفاع الديناميكي)
  Widget _buildPaymentsSection(BuildContext context) {
    final cubit = StudentCubit.get(context);
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
                // تمنع الـ Overflow وتجعلها تتمدد مع الـ Column
                physics: const NeverScrollableScrollPhysics(),
                // تجعل السكرول تابعاً للصفحة بالكامل
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  // البحث عن الدفعة المقابلة للطالب
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
  // 11. بناء قسم الملاحظات (NotesPart)
  Widget _buildNotesSection(BuildContext context, StudentCubit cubit) {
    return TextFormField(
      controller: cubit.noteController,
      maxLines: 3,
      style: AppTextStyles.customText(color: AppColors.textPrimary),
      decoration: _getInputDecoration("إضافة ملاحظة").copyWith(
        hintText: 'اكتب ملاحظتك هنا...',
      ),
    );
  }

  // 12. بناء زر الحفظ/الإضافة
  Widget _buildSaveButton(BuildContext context, StudentCubit cubit) {
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
              // التحقق من صحة النموذج قبل الإضافة
              if (_formKey.currentState!.validate()) {
                await cubit.addStudent(context, widget.grade);
              }
            },
            child: Text("إضافة الطالب",
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