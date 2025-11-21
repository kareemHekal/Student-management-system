import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/AddMogmo3a/add_mogmo3a_cubit.dart';
import '../bloc/AddMogmo3a/add_mogmo3a_state.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';

class AddMagmo3a extends StatelessWidget {
  final Magmo3amodel? existingMagmo3a;
  final String? oldDay;

  const AddMagmo3a({super.key, this.existingMagmo3a, this.oldDay});

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(existingMagmo3a == null
                    ? 'تمت الإضافة بنجاح'
                    : 'تم التعديل بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is Magmo3aError) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("خطأ"),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("حسنًا"),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.watch<Magmo3aCubit>();
          return Container(
            decoration: const BoxDecoration(
              color: app_colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDropdown(
                    "اليوم",
                    "اختر اليوم",
                    cubit.days,
                    cubit.chosenDay,
                    (value) => cubit.selectDay(value),
                  ),
                  const Divider(color: app_colors.darkGrey, thickness: 3),
                  _buildTimePicker(context, cubit),
                  const Divider(color: app_colors.darkGrey, thickness: 3),
                  _buildDropdown(
                    "المرحلة الدراسية",
                    "اختر المرحلة الدراسية",
                    cubit.secondaries,
                    cubit.selectedSecondary,
                    (value) => cubit.selectSecondary(value),
                  ),
                  const SizedBox(height: 30),
                  state is Magmo3aLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: app_colors.green,
                            backgroundColor: app_colors.darkGrey,
                          ),
                          onPressed: () async {
                            if (existingMagmo3a == null) {
                              cubit.addMagmo3a();
                            } else {
                              final updatedMagmo3a = Magmo3amodel(
                                id: existingMagmo3a!.id,
                                days: cubit.chosenDay,
                                grade: cubit.selectedSecondary,
                                time: cubit.timeOfDay,
                              );

                              await FirebaseFunctions.editMagmo3aInDay(
                          oldDay ?? existingMagmo3a!.days!,
                          existingMagmo3a!.grade!,
                          updatedMagmo3a,
                        );

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم التعديل بنجاح'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child:
                              Text(existingMagmo3a == null ? "إضافة" : "تعديل"),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        DropdownButton<String>(
          dropdownColor: app_colors.darkGrey,
          value: selectedValue,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: app_colors.darkGrey)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child:
                  Text(item, style: const TextStyle(color: app_colors.green)),
            );
          }).toList(),
          onChanged: (value) => onChanged(value!),
          underline: Container(height: 2, color: app_colors.green),
          icon: const Icon(Icons.arrow_forward_ios_outlined,
              color: app_colors.green),
        ),
      ],
    );
  }

  Widget _buildTimePicker(BuildContext context, Magmo3aCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الوقت", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: cubit.timeOfDay,
                );
                if (pickedTime != null) cubit.pickTime(pickedTime);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: app_colors.green,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: app_colors.darkGrey, width: 1.5),
                ),
                padding: const EdgeInsets.all(8.0),
                child: const Text("اختر الوقت"),
              ),
            ),
            Text(
              "${cubit.timeOfDay.hourOfPeriod}:${cubit.timeOfDay.minute.toString().padLeft(2, '0')} ${cubit.timeOfDay.period == DayPeriod.am ? 'ص' : 'م'}",
              style: const TextStyle(fontSize: 30),
            ),
          ],
        ),
      ],
    );
  }
}
