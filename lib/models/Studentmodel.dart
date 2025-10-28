import 'Magmo3aModel.dart';
import 'absence_model.dart';
import 'day_record.dart';
import 'student_exam_grade.dart';
import 'student_paid_subscription.dart';

/// A model representing a student and their associated data.
class Studentmodel {
  // Basic student details
  String id;
  String? name;
  String? grade;
  String? gender;
  String? phoneNumber;
  String? motherPhone;
  String? fatherPhone;

  // Lists for related data
  List<Magmo3amodel>? hisGroups;
  List<String>? hisGroupsId;
  List<AbsenceModel>? absencesNumbers;
  List<StudentPaidSubscriptions>? studentPaidSubscriptions;
  List<StudentExamGrade>? studentExamsGrades;
  List<DayRecord>? countingAttendedDays;
  List<DayRecord>? countingAbsentDays;

  // Additional student information
  String? note;
  String? dateofadd;

  Studentmodel({
    this.id = "",
    this.hisGroups,
    this.hisGroupsId,
    this.grade,
    this.name,
    this.gender,
    this.phoneNumber,
    this.absencesNumbers,
    this.motherPhone,
    this.fatherPhone,
    this.note,
    this.dateofadd,
    this.studentPaidSubscriptions,
    this.studentExamsGrades,
    this.countingAttendedDays,
    this.countingAbsentDays,
  });

  /// Factory method to create a `Studentmodel` instance from a JSON object.
  factory Studentmodel.fromJson(Map<String, dynamic> json) {
    return Studentmodel(
      id: json['id'] ?? "",
      name: json['name'],
      motherPhone: json['mothernumber'],
      phoneNumber: json['phonenumber'],
      note: json['note'],
      dateofadd: json['dateofadd'],
      gender: json['gender'],
      grade: json['grade'],
      fatherPhone: json['fatherphone'],

      hisGroups: (json['hisGroups'] as List<dynamic>?)
              ?.map((group) =>
                  Magmo3amodel.fromJson(Map<String, dynamic>.from(group)))
              .toList() ??
          [],
      hisGroupsId: (json['hisGroupsId'] as List<dynamic>?)
          ?.map((id) => id.toString())
              .toList() ??
          [],
      absencesNumbers: (json['absencesNumbers'] as List<dynamic>?)
              ?.map((item) =>
                  AbsenceModel.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      studentPaidSubscriptions:
          (json['studentPaidSubscriptions'] as List<dynamic>?)
                  ?.map((sub) => StudentPaidSubscriptions.fromJson(
                      Map<String, dynamic>.from(sub)))
                  .toList() ??
              [],
      studentExamsGrades: (json['studentExamsGrades'] as List<dynamic>?)
              ?.map((exam) =>
                  StudentExamGrade.fromJson(Map<String, dynamic>.from(exam)))
              .toList() ??
          [],
      countingAttendedDays: (json['countingAttendedDays'] as List<dynamic>?)
              ?.map((day) => DayRecord.fromJson(Map<String, dynamic>.from(day)))
              .toList() ??
          [],
      countingAbsentDays: (json['countingAbsentDays'] as List<dynamic>?)
              ?.map((day) => DayRecord.fromJson(Map<String, dynamic>.from(day)))
              .toList() ??
          [],
    );
  }

  /// Converts the `Studentmodel` instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gender': gender ?? '',
      'grade': grade ?? '',
      'dateofadd': dateofadd ?? '',
      'note': note ?? '',
      'name': name ?? '',
      'fatherphone': fatherPhone ?? '',
      'mothernumber': motherPhone ?? '',
      'phonenumber': phoneNumber ?? '',
      'hisGroups': hisGroups?.map((group) => group.toJson()).toList() ?? [],
      'hisGroupsId': hisGroupsId ?? [],
      'absencesNumbers':
          absencesNumbers?.map((abs) => abs.toJson()).toList() ?? [],
      'studentPaidSubscriptions':
          studentPaidSubscriptions?.map((sub) => sub.toJson()).toList() ?? [],
      'studentExamsGrades':
          studentExamsGrades?.map((exam) => exam.toJson()).toList() ?? [],
      'countingAttendedDays':
          countingAttendedDays?.map((day) => day.toJson()).toList() ?? [],
      'countingAbsentDays':
          countingAbsentDays?.map((day) => day.toJson()).toList() ?? [],
    };
  }

  @override
  String toString() {
    return 'Studentmodel(id: $id, name: $name, grade: $grade, gender: $gender, phone: $phoneNumber, exams: ${studentExamsGrades?.length ?? 0}, attended: ${countingAttendedDays?.length ?? 0}, absent: ${countingAbsentDays?.length ?? 0})';
  }
}
