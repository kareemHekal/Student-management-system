import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

import '../bloc/AddMogmo3a/add_mogmo3a_cubit.dart';
import '../bloc/AddMogmo3a/add_mogmo3a_state.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';
import '../theme/colors_app.dart';

class AddMagmo3a extends StatelessWidget {
  final Magmo3amodel? existingMagmo3a;
  final String? oldDay;

  const AddMagmo3a({super.key, this.existingMagmo3a, this.oldDay});

  // Mapping for Arabic UI to English Logic
  static const Map<String, String> dayMapping = {
    'السبت': 'Saturday',
    'الأحد': 'Sunday',
    'الاثنين': 'Monday',
    'الثلاثاء': 'Tuesday',
    'الأربعاء': 'Wednesday',
    'الخميس': 'Thursday',
    'الجمعة': 'Friday',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = Magmo3aCubit()..fetchGrades();
        if (existingMagmo3a != null) {
          cubit.initializeFromExisting(existingMagmo3a!);
        }
        return cubit;
      },
      child: BlocConsumer<Magmo3aCubit, Magmo3aState>(
        listener: (context, state) {
          if (state is Magmo3aSuccess) {
            Navigator.pop(context);
            AppSnackBars.showSuccess(
                context,
                existingMagmo3a == null
                    ? 'تمت إضافة المجموعة بنجاح ✅'
                    : 'تم تعديل المجموعة بنجاح ✅');
          } else if (state is Magmo3aError) {
            AppSnackBars.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final cubit = context.watch<Magmo3aCubit>();

          // Reverse lookup to find Arabic name for the current chosenDay (which is English in logic)
          String? currentArabicDay = dayMapping.entries
              .where((entry) => entry.value == cubit.chosenDay)
              .map((entry) => entry.key)
              .firstOrNull;

          return Container(
            // Fix: clipBehavior ensures the header doesn't show white corners underneath
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMain,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        existingMagmo3a == null
                            ? Icons.group_add_rounded
                            : Icons.edit_calendar_rounded,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        existingMagmo3a == null
                            ? "إضافة مجموعة جديدة"
                            : "تعديل بيانات المجموعة",
                        style: AppTextStyles.customText(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Content ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDropdownField(
                          context,
                          label: "يوم المحاضرة",
                          hint: "اختر اليوم",
                          items: dayMapping.keys.toList(),
                          // Show Arabic Days
                          selectedValue: currentArabicDay,
                          onChanged: (arabicValue) {
                            // Convert back to English for logic
                            String englishDay = dayMapping[arabicValue]!;
                            cubit.selectDay(englishDay);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTimePickerField(context, cubit),
                        const SizedBox(height: 20),
                        existingMagmo3a != null
                            ? const SizedBox.shrink()
                            : _buildDropdownField(
                                context,
                                label: "المرحلة الدراسية",
                                hint: "اختر المرحلة",
                                items: cubit.secondaries,
                                selectedValue: cubit.selectedSecondary,
                                onChanged: (value) =>
                                    cubit.selectSecondary(value),
                              ),
                        const SizedBox(height: 35),
                        state is Magmo3aLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMain,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (existingMagmo3a == null) {
                                      cubit.addMagmo3a();
                                    } else {
                                      final updatedMagmo3a = Magmo3amodel(
                                        id: existingMagmo3a!.id,
                                        day: cubit.chosenDay,
                                        // Logic remains English
                                        grade: cubit.selectedSecondary,
                                        time: cubit.timeOfDay,
                                      );

                                      await FirebaseFunctions.editMagmo3aInDay(
                                        oldDay ?? existingMagmo3a!.day!,
                                        existingMagmo3a!.grade!,
                                  updatedMagmo3a,
                                );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        AppSnackBars.showSuccess(
                                            context, 'تم التعديل بنجاح ✅');
                                      }
                                    }
                                  },
                                  child: Text(
                                    existingMagmo3a == null ? "إضافة" : "تعديل",
                                    style: AppTextStyles.customText(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required String hint,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.customText(
                fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              hint: Text(hint),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryMain),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: AppTextStyles.customText(
                          fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (value) => onChanged(value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField(BuildContext context, Magmo3aCubit cubit) {
    String formattedTime =
        "${cubit.timeOfDay.hourOfPeriod}:${cubit.timeOfDay.minute.toString().padLeft(2, '0')} ${cubit.timeOfDay.period == DayPeriod.am ? 'ص' : 'م'}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("وقت المحاضرة",
            style: AppTextStyles.customText(
                fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: cubit.timeOfDay,
            );
            if (pickedTime != null) cubit.pickTime(pickedTime);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primaryMain.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryMain.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.primaryMain),
                const SizedBox(width: 15),
                Text(formattedTime,
                    style: AppTextStyles.customText(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMain)),
                const Spacer(),
                const Icon(Icons.edit_calendar_outlined,
                    size: 18, color: AppColors.primaryMain),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
