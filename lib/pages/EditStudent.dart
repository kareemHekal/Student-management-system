// Import necessary packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/Edit Student/edit_student_cubit.dart';
import '../bloc/Edit Student/edit_student_state.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';

class EditStudentScreen extends StatefulWidget {
  final Studentmodel student;
  final String? grade;

  const EditStudentScreen({
    required this.student,
    required this.grade,
    Key? key,
  }) : super(key: key);

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  // Controllers and other state variables remain mostly the same
  late TextEditingController nameController;
  late TextEditingController studentNumberController;
  late TextEditingController fatherNumberController;
  late TextEditingController motherNumberController;
  late TextEditingController noteController;
  late TextEditingController totalAmountController;
  late TextEditingController descriptionController;

  String? _selectedGender;
  bool? _firstMonth, _secondMonth, _thirdMonth, _fourthMonth, _fifthMonth;
  bool? _explainingNote, _reviewNote;
  List<Magmo3amodel>? hisGroups;
  List<String>? hisGroupsId;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and state variables with original student data
    nameController = TextEditingController(text: widget.student.name);
    studentNumberController = TextEditingController(text: widget.student.phoneNumber);
    fatherNumberController = TextEditingController(text: widget.student.fatherPhone);
    motherNumberController = TextEditingController(text: widget.student.motherPhone);
    noteController = TextEditingController(text: widget.student.note);
    totalAmountController = TextEditingController();
    descriptionController = TextEditingController();

    _selectedGender = widget.student.gender;
    _firstMonth = widget.student.firstMonth;
    _secondMonth = widget.student.secondMonth;
    _thirdMonth = widget.student.thirdMonth;
    _fourthMonth = widget.student.fourthMonth;
    _fifthMonth = widget.student.fifthMonth;
    _explainingNote = widget.student.explainingNote;
    _reviewNote = widget.student.reviewNote;

    hisGroups = widget.student.hisGroups;
    hisGroupsId = widget.student.hisGroupsId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentEditCubit, StudentEditState>(
      listener: (context, state) {
        if (state is StudentEditSuccess) {
          bool isMonthOrNoteChanged = _checkMonthOrNoteChanged();
          if (isMonthOrNoteChanged) {
            _showPaymentChangeDialog(context);
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Student Edited successfully!'),
              ),
            );
          }
        } else if (state is StudentEditFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Error: ${state.errorMessage}'),
            ),
          );
        }
      },
      child: Scaffold(
        // Your existing UI code, replacing direct Firebase update with Cubit calls
        body: BlocBuilder<StudentEditCubit, StudentEditState>(
          builder: (context, state) {
            return Column(
              children: [
                // Existing widgets
                ElevatedButton(
                  onPressed: () {
                    // Validate inputs and call Cubit method
                    if (_validateInputs()) {
                      context.read<StudentEditCubit>().updateStudent(
                        originalStudent: widget.student,
                        grade: widget.grade,
                        hisGroups: hisGroups,
                        hisGroupsId: hisGroupsId,
                        name: nameController.text,
                        gender: _selectedGender,
                        studentNumber: studentNumberController.text,
                        fatherNumber: fatherNumberController.text,
                        motherNumber: motherNumberController.text,
                        note: noteController.text,
                        firstMonth: _firstMonth,
                        secondMonth: _secondMonth,
                        thirdMonth: _thirdMonth,
                        fourthMonth: _fourthMonth,
                        fifthMonth: _fifthMonth,
                        explainingNote: _explainingNote,
                        reviewNote: _reviewNote,
                      );
                    }
                  },
                  child: const Text('Edit'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _validateInputs() {
    // Add your validation logic here
    return true;
  }

  bool _checkMonthOrNoteChanged() {
    return (widget.student.firstMonth == false && _firstMonth == true) ||
        (widget.student.secondMonth == false && _secondMonth == true) ||
        (widget.student.thirdMonth == false && _thirdMonth == true) ||
        (widget.student.fourthMonth == false && _fourthMonth == true) ||
        (widget.student.fifthMonth == false && _fifthMonth == true) ||
        (widget.student.explainingNote == false && _explainingNote == true) ||
        (widget.student.reviewNote == false && _reviewNote == true);
  }

  void _showPaymentChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalAmountController,
              decoration: const InputDecoration(labelText: 'Total Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<StudentEditCubit>().createInvoiceForPaymentChanges(
                studentName: nameController.text,
                studentPhoneNumber: studentNumberController.text,
                momPhoneNumber: motherNumberController.text,
                dadPhoneNumber: fatherNumberController.text,
                grade: widget.grade ?? '',
                totalAmount: double.tryParse(totalAmountController.text) ?? 0.0,
                description: descriptionController.text,
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}