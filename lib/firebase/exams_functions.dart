import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Studentmodel.dart';
import '../models/exam_model.dart';
import '../models/mini_exam.dart';
import '../models/student_exam_grade.dart';
import 'firebase_functions.dart';

class FirebaseExams {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('exams');

  /// Get all exams for a grade
  static Stream<List<ExamModel>> getExamsStream(String gradeName) {
    return _collection.doc(gradeName).snapshots().map((docSnapshot) {
      if (!docSnapshot.exists) return [];
      final data = docSnapshot.data();
      if (data == null || data['exams'] == null) return [];

      final examsList = (data['exams'] as List<dynamic>)
          .map((e) => ExamModel.fromJson(e))
          .toList();
      return examsList;
    });
  }

  static Future<List<ExamModel>> getExams(String gradeName) async {
    final doc = await _collection.doc(gradeName).get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null || data['exams'] == null) return [];

    return (data['exams'] as List<dynamic>)
        .map((e) => ExamModel.fromJson(e))
        .toList();
  }

  /// Add a new exam to a grade with auto-generated ID
  static Future<void> addExam(String gradeName, ExamModel exam) async {
    final docRef = _collection.doc(gradeName);

    // Generate Firestore ID if exam.id is null
    final newExamId =
        exam.id ?? FirebaseFirestore.instance.collection('tmp').doc().id;
    final newExam = exam.copyWith(id: newExamId);

    await docRef.set({
      'exams': FieldValue.arrayUnion([newExam.toJson()])
    }, SetOptions(merge: true)); // <-- merge ensures doc is created if missing
  }

  /// Update an exam by its ID
  static Future<void> updateExam(String gradeName, ExamModel exam) async {
    final docRef = _collection.doc(gradeName);
    final exams = await getExams(gradeName);
    final index = exams.indexWhere((e) => e.id == exam.id);
    if (index == -1) return;
    exams[index] = exam;
    await docRef.update({
      'exams': exams.map((e) => e.toJson()).toList(),
    });
  }

  /// Delete an exam by its ID
  static Future<void> deleteExam(String gradeName, String examId) async {
    final docRef = _collection.doc(gradeName);

    // 1. Remove the exam from the exams list
    final exams = await getExams(gradeName);
    exams.removeWhere((e) => e.id == examId);
    await docRef.update({
      'exams': exams.map((e) => e.toJson()).toList(),
    });

    // 2. Get all students in this grade
    final students =
        await FirebaseFunctions.getAllStudentsByGrade_future(gradeName);

    // 3. Update each student by removing the exam from their studentExamsGrades
    for (final student in students) {
      final updatedExams = student.studentExamsGrades
              ?.where((grade) => grade.examId != examId)
              .toList() ??
          [];

      // Only update if there was a change
      if (updatedExams.length != (student.studentExamsGrades?.length ?? 0)) {
        student.studentExamsGrades = updatedExams;

        // Save the updated student back to Firestore
        await FirebaseFunctions.getSecondaryCollection(gradeName)
            .doc(student.id)
            .update(student.toJson());
      }
    }
  }

  static Future<Studentmodel?> getStudent(
      String gradeName, String studentId) async {
    final doc = await FirebaseFunctions.getSecondaryCollection(gradeName)
        .doc(studentId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> addStudentExamGrade(
      String gradeName, String studentId, StudentExamGrade grade) async {
    final studentDoc =
        FirebaseFunctions.getSecondaryCollection(gradeName).doc(studentId);
    final student = await getStudent(gradeName, studentId);
    if (student == null) return;

    student.studentExamsGrades ??= [];
    student.studentExamsGrades!.add(grade);

    await studentDoc.update(student.toJson());
  }

  static Future<MiniExam?> getMiniExamById(
    String gradeName,
    String examId,
    String miniExamId,
  ) async {
    final doc = await _collection.doc(gradeName).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['exams'] == null) return null;

    final exams = (data['exams'] as List<dynamic>)
        .map((e) => ExamModel.fromJson(e))
        .toList();

    // Find the exam
    final exam = exams.firstWhere(
      (exam) => exam.id == examId,
      orElse: () => ExamModel(id: null, name: '', miniExams: []),
    );

    if (exam.id == null || exam.miniExams == null) return null;

    // Find the mini exam
    try {
      return exam.miniExams!.firstWhere((mini) => mini.id == miniExamId);
    } catch (e) {
      return null;
    }
  }

  /// Get a single exam by its ID for a specific grade
  static Future<ExamModel?> getExamById(String gradeName, String examId) async {
    final doc = await _collection.doc(gradeName).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['exams'] == null) return null;

    final exams = (data['exams'] as List<dynamic>)
        .map((e) => ExamModel.fromJson(e))
        .toList();

    try {
      return exams.firstWhere((exam) => exam.id == examId);
    } catch (e) {
      // If no match found, return null
      return null;
    }
  }

  static Future<void> updateStudentExamGrade({
    required String gradeName,
    required String studentId,
    required StudentExamGrade updatedGrade,
  }) async {
    final studentDoc =
        FirebaseFunctions.getSecondaryCollection(gradeName).doc(studentId);
    final student = await getStudent(gradeName, studentId);
    if (student == null) return;

    // Ensure list exists
    student.studentExamsGrades ??= [];

    // Find the index of the existing grade using IDs from the updated model
    final index = student.studentExamsGrades!.indexWhere(
      (grade) =>
          grade.examId == updatedGrade.examId &&
          grade.miniExamId == updatedGrade.miniExamId,
    );

    if (index == -1) return; // not found, nothing to update

    // Replace the old one with the updated model
    student.studentExamsGrades![index] = updatedGrade;

    // Update Firestore document
    await studentDoc.update(student.toJson());
  }

  /// Delete a student exam grade by exam ID and mini exam ID
  static Future<void> deleteStudentExamGrade({
    required String gradeName,
    required String studentId,
    required String examId,
    required String miniExamId,
  }) async {
    // Get student document reference
    final studentDoc =
        FirebaseFunctions.getSecondaryCollection(gradeName).doc(studentId);

    // Fetch student data
    final student = await getStudent(gradeName, studentId);
    if (student == null || student.studentExamsGrades == null) return;

    // Remove the matching grade
    student.studentExamsGrades!.removeWhere(
      (grade) => grade.examId == examId && grade.miniExamId == miniExamId,
    );

    // Update Firestore with new list
    await studentDoc.update(student.toJson());
  }
}
