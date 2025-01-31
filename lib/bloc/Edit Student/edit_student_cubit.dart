import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../firebase/firebase_functions.dart';
import '../../models/Big invoice.dart';
import '../../models/Invoice.dart';
import '../../models/Magmo3aModel.dart';
import '../../models/Studentmodel.dart';
import 'edit_student_state.dart';


class StudentEditCubit extends Cubit<StudentEditState> {
  StudentEditCubit() : super(StudentEditInitial());

  Future<void> updateStudent({
    required Studentmodel originalStudent,
    required String? grade,
    required List<Magmo3amodel>? hisGroups,
    required List<String>? hisGroupsId,
    required String name,
    required String? gender,
    required String studentNumber,
    required String fatherNumber,
    required String motherNumber,
    required String note,
    required bool? firstMonth,
    required bool? secondMonth,
    required bool? thirdMonth,
    required bool? fourthMonth,
    required bool? fifthMonth,
    required bool? explainingNote,
    required bool? reviewNote,
  }) async {
    emit(StudentEditLoading());

    try {
      String? currentDate = DateTime.now().toIso8601String().substring(0, 10);

      // Determine payment dates based on changes
      String? dateOfFirstMonthPaid = firstMonth != originalStudent.firstMonth
          ? firstMonth == true ? currentDate : null
          : originalStudent.dateOfFirstMonthPaid;

      String? dateOfSecondMonthPaid = secondMonth != originalStudent.secondMonth
          ? secondMonth == true ? currentDate : null
          : originalStudent.dateOfSecondMonthPaid;

      String? dateOfThirdMonthPaid = thirdMonth != originalStudent.thirdMonth
          ? thirdMonth == true ? currentDate : null
          : originalStudent.dateOfThirdMonthPaid;

      String? dateOfFourthMonthPaid = fourthMonth != originalStudent.fourthMonth
          ? fourthMonth == true ? currentDate : null
          : originalStudent.dateOfFourthMonthPaid;

      String? dateOfFifthMonthPaid = fifthMonth != originalStudent.fifthMonth
          ? fifthMonth == true ? currentDate : null
          : originalStudent.dateOfFifthMonthPaid;

      String? dateOfExplainingNotePaid = explainingNote != originalStudent.explainingNote
          ? explainingNote == true ? currentDate : null
          : originalStudent.dateOfExplainingNotePaid;

      String? dateOfReviewingNotePaid = reviewNote != originalStudent.reviewNote
          ? reviewNote == true ? currentDate : null
          : originalStudent.dateOfReviewingNotePaid;

      Studentmodel updatedStudent = Studentmodel(
        id: originalStudent.id,
        dateofadd: originalStudent.dateofadd,
        name: name,
        gender: gender,
        hisGroups: hisGroups,
        hisGroupsId: hisGroupsId,
        grade: grade,
        firstMonth: firstMonth,
        secondMonth: secondMonth,
        thirdMonth: thirdMonth,
        note: note,
        fourthMonth: fourthMonth,
        fifthMonth: fifthMonth,
        explainingNote: explainingNote,
        reviewNote: reviewNote,
        phoneNumber: studentNumber,
        motherPhone: motherNumber,
        fatherPhone: fatherNumber,
        dateOfFirstMonthPaid: dateOfFirstMonthPaid,
        dateOfSecondMonthPaid: dateOfSecondMonthPaid,
        dateOfThirdMonthPaid: dateOfThirdMonthPaid,
        dateOfFourthMonthPaid: dateOfFourthMonthPaid,
        dateOfFifthMonthPaid: dateOfFifthMonthPaid,
        dateOfExplainingNotePaid: dateOfExplainingNotePaid,
        dateOfReviewingNotePaid: dateOfReviewingNotePaid,
      );

      await FirebaseFunctions.updateStudentInCollection(
        originalStudent.grade ?? "",
        originalStudent.id,
        updatedStudent,
      );

      emit(StudentEditSuccess(updatedStudent: updatedStudent));
    } catch (e) {
      emit(StudentEditFailure(errorMessage: e.toString()));
    }
  }

  Future<void> createInvoiceForPaymentChanges({
    required String studentName,
    required String studentPhoneNumber,
    required String momPhoneNumber,
    required String dadPhoneNumber,
    required String grade,
    required double totalAmount,
    required String description,
  }) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String currentDate = DateTime.now().toIso8601String().substring(0, 10);
      String currentDay = _getCurrentDay();

      DocumentSnapshot docSnapshot = await firestore.collection('big_invoices').doc(currentDate).get();

      Invoice newInvoice = Invoice(
        studentName: studentName,
        studentPhoneNumber: studentPhoneNumber,
        momPhoneNumber: momPhoneNumber,
        dadPhoneNumber: dadPhoneNumber,
        grade: grade,
        amount: totalAmount,
        description: description,
        dateTime: DateTime.now(),
      );

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        BigInvoice bigInvoice = BigInvoice.fromJson(data);
        bigInvoice.invoices.add(newInvoice);

        await firestore.collection('big_invoices').doc(currentDate).update(bigInvoice.toJson());
      } else {
        BigInvoice bigInvoice = BigInvoice(
          date: currentDate,
          day: currentDay,
          invoices: [newInvoice],
          payments: [],
        );

        await firestore.collection('big_invoices').doc(currentDate).set(bigInvoice.toJson());
      }
    } catch (e) {
      // You might want to handle or log the error
      print('Error creating invoice: $e');
    }
  }

  String _getCurrentDay() {
    DateTime now = DateTime.now();
    switch (now.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
}