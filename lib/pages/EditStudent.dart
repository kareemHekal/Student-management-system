import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../Alert dialogs/RemoveFromGroupsListDialog.dart';
import '../BottomSheets/student_actions_bottom_sheet.dart';
import '../bloc/Edit Student/edit_student_cubit.dart';
import '../bloc/Edit Student/edit_student_state.dart';
import '../cards/groupSmallCard.dart';
import '../cards/student_subscriptions_card.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Studentmodel.dart';
import '../models/grade_subscriptions_model.dart';
import '../models/student_paid_subscription.dart';
import 'Pick Groups Page.dart';
import 'all_absent_numbers.dart';

class EditStudentScreen extends StatefulWidget {
  Studentmodel student;
  String? grade;

  EditStudentScreen({required this.student, required this.grade, super.key});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: BlocProvider(
        create: (context) =>
            StudentEditCubit(student: widget.student)..initTheState(),
        child: Scaffold(
            appBar: AppBar(
              elevation: 10,
              shadowColor: Colors.yellow,
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
                    color: app_colors.green,
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
                icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
              ),
              backgroundColor: app_colors.darkGrey,
              title: Image.asset(
                "assets/images/logo.png",
                height: 100,
                width: 90,
              ),
              toolbarHeight: 180,
            ),
            body: LoaderOverlay(
              child: BlocConsumer<StudentEditCubit, StudentEditState>(
                listener: (context, state) {
                  if (state is StudentEditLoading) {
                    context.loaderOverlay.show();
                  } else {
                    context.loaderOverlay.hide();
                  }
                  if (state is StudentEditSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تعديل بيانات الطالب بنجاح!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  if (state is StudentUpdatedInEditPage) {
                    setState(() {});
                  }
                  if (state is StudentEditFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  if (state is StudentValidationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is StudentEditLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cubit = StudentEditCubit.get(context);

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Center(
                            child: Image.asset("assets/images/logo.png")),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 17),
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
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 20, left: 0),
                                              child: Text(
                                                textAlign: TextAlign.start,
                                                '''تعديل بيانات الطالب''',
                                                style: GoogleFonts.oswald(
                                                  fontSize: 30,
                                                  color: app_colors.darkGrey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        SizedBox(
                                          height: 240,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Center(
                                                  child: Text("اختر الأيام")),
                                              Expanded(
                                                child: PickGroupRow(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        TextFormFields(context),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        MaleOrFemalePart(context),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        paymentsPart(context),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            showNumberOfAbsenceAndPresence(
                                                "أيام الحضور",
                                                widget
                                                    .student
                                                    .countingAttendedDays
                                                    ?.length),
                                            showNumberOfAbsenceAndPresence(
                                                "أيام الغياب",
                                                widget
                                                    .student
                                                    .countingAbsentDays
                                                    ?.length),
                                            IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        AbsencesListPage(
                                                      absences: widget.student
                                                              .absencesNumbers ??
                                                          [],
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                Icons.calendar_month,
                                                color: app_colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(
                                          color: app_colors.green,
                                          thickness: 4,
                                        ),
                                        const SizedBox(height: 20),
                                        NotesPart(context),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor:
                                                      app_colors.green,
                                                  backgroundColor:
                                                      app_colors.darkGrey,
                                                ),
                                                onPressed: () async {
                                                  await cubit.EditStudent(
                                                      context, widget.grade);
                                                },
                                                child: const Text("تعديل"),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 200),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  );
                },
              ),
            )),
      ),
    );
  }

  Widget MaleOrFemalePart(BuildContext context) {
    final cubit = StudentEditCubit.get(context);
    return Column(
      children: [
        Container(
            decoration: BoxDecoration(
              border: Border.all(color: app_colors.darkGrey, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              dropdownColor: app_colors.darkGrey,
              value: cubit.selectedGender ?? "ذكر",
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: "ذكر",
                  child: Text("ذكر", style: TextStyle(color: app_colors.green)),
                ),
                DropdownMenuItem(
                  value: "أنثى",
                  child:
                      Text("أنثى", style: TextStyle(color: app_colors.green)),
                ),
              ],
              onChanged: (value) {
                cubit.changeValueOfGenderDropDown(value);
              },
              elevation: 8,
              style: const TextStyle(color: app_colors.green),
              icon: const Icon(Icons.arrow_forward_ios_outlined,
                  color: app_colors.green),
              iconSize: 24,
              hint: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  cubit.selectedGender ?? "اختر الجنس",
                  style: const TextStyle(color: app_colors.green),
                ),
              ),
            )),
        const SizedBox(
          height: 15,
        ),
        cubit.selectedGender != null
            ? Wrap(
                direction: Axis.horizontal,
                spacing: 8,
                children: [
                  Chip(
                    backgroundColor: app_colors.darkGrey,
                    label: Text(cubit.selectedGender!,
                        style: const TextStyle(color: app_colors.green)),
                    deleteIcon: const Icon(Icons.cancel,
                        size: 20, color: app_colors.green),
                    shape: const StadiumBorder(
                        side: BorderSide(color: app_colors.green)),
                    onDeleted: () {
                      cubit.setTheSelectedGenderByNull();
                    },
                  ),
                ],
              )
            : const Center(
                child: Text("اختر الجنس",
                    style: TextStyle(color: app_colors.green)),
              ),
      ],
    );
  }

  Widget TextFormFields(BuildContext context) {
    final cubit = StudentEditCubit.get(context);

    InputDecoration getInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 25, color: app_colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: app_colors.darkGrey, width: 2.0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: app_colors.darkGrey, width: 2.0),
          borderRadius: BorderRadius.circular(20.0),
        ),
      );
    }

    Widget buildTextFormField({
      required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
    }) {
      return TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'من فضلك أدخل $label';
          }
          return null;
        },
        decoration: getInputDecoration(label),
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
      );
    }

    return Column(
      children: [
        buildTextFormField(
            controller: cubit.name_controller, label: "اسم الطالب"),
        const SizedBox(height: 15),
        buildTextFormField(
          controller: cubit.studentNumberController,
          label: "رقم الطالب",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15),
        buildTextFormField(
          controller: cubit.fatherNumberController,
          label: "رقم ولي الأمر",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),
        buildTextFormField(
          controller: cubit.motherNumberController,
          label: "رقم الأم",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget showNumberOfAbsenceAndPresence(
    String label,
    int? number,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (number ?? 0).toString(),
              style: const TextStyle(fontSize: 16, color: app_colors.green),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget PickGroupRow(BuildContext context) {
    final cubit = StudentEditCubit.get(context);
    return Column(
      children: [
        Expanded(
            child: cubit.hisGroups == []
                ? Center(
                    child: Text(
                    "لم تقم باختيار أي مجموعة بعد",
                    style: TextStyle(color: app_colors.green),
                  ))
                : ListView.builder(
                    itemCount: cubit.hisGroups?.length,
                    itemBuilder: (context, index) {
                      final magmo3aModel = cubit.hisGroups?[index];
                      return GestureDetector(
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return RemoveFromGroupsListDialog(
                                  title: "حذف المجموعة",
                                  content:
                                      "هل أنت متأكد أنك تريد إزالة هذه المجموعة؟",
                                  onConfirm: () async {
                                    await Future.delayed(
                                        Duration(milliseconds: 1));
                                    cubit.hisGroups?.removeAt(index);
                                    cubit.hisGroupsId?.removeAt(index);
                                    setState(() {});
                                  },
                                );
                              },
                            );
                          },
                          child: Groupsmallcard(magmo3aModel: magmo3aModel));
                    },
                  )),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: const BorderSide(color: app_colors.green, width: 1),
            foregroundColor: app_colors.green,
            backgroundColor: app_colors.darkGrey,
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
          child: const Text("إضافة مجموعة"),
        ),
      ],
    );
  }

  Widget NotesPart(BuildContext context) {
    final cubit = StudentEditCubit.get(context);

    return TextFormField(
      controller: cubit.noteController,
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'من فضلك أدخل ملاحظة';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "إضافة ملاحظة",
        labelStyle: const TextStyle(fontSize: 25, color: app_colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: app_colors.darkGrey, width: 2.0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: app_colors.darkGrey, width: 2.0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        hintText: 'اكتب ملاحظتك هنا...',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget paymentsPart(BuildContext context) {
    final cubit = StudentEditCubit.get(context);

    return StreamBuilder<GradeSubscriptionsModel?>(
      stream: FirebaseFunctions.getGradeSubscriptionsStream(widget.grade ?? ""),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text(
              'لا توجد اشتراكات لهذا الصف حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final gradeSubs = snapshot.data!;
        final subscriptions = gradeSubs.subscriptions;
        final studentPaidSubscriptions = cubit.studentPaidSubscriptions;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الاشتراكات (${subscriptions.length})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: app_colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Show cards horizontally
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = subscriptions[index];
                    // Try to find matching student payment
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
                      child: StudentSubscriptionsCard(
                        studentPaidSubscription: paidSub,
                        subscriptionFee: sub,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
