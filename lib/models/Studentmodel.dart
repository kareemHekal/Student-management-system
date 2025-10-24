import 'Magmo3aModel.dart';
import 'absence_model.dart';
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

  // Additional student information
  String? note;
  String? dateofadd;
  int? numberOfAbsentDays;
  int? numberOfAttendantDays;
  String? lastDayStudentCame;
  String? lastDateStudentCame;


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
    this.numberOfAbsentDays,
    this.numberOfAttendantDays,
    this.lastDayStudentCame,
    this.lastDateStudentCame,
    this.studentPaidSubscriptions,
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
      numberOfAbsentDays: json['numberOfAbsentDays'],
      numberOfAttendantDays: json['numberOfAttendantDays'],
      lastDayStudentCame: json['lastDayStudentCame'],
      lastDateStudentCame: json['lastDateStudentCame'],

      // 🔹 Convert JSON lists to proper Dart lists
      hisGroups: (json['hisGroups'] as List<dynamic>?)
          ?.map((group) => Magmo3amodel.fromJson(group))
          .toList(),
      hisGroupsId: (json['hisGroupsId'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList(),
      absencesNumbers: (json['absencesNumbers'] as List<dynamic>?)
          ?.map((item) => AbsenceModel.fromJson(item))
          .toList(),

      // 🔹 Convert JSON list to `StudentPaidSubscription`
      studentPaidSubscriptions:
          (json['studentPaidSubscriptions'] as List<dynamic>?)
              ?.map((sub) => StudentPaidSubscriptions.fromJson(sub))
              .toList(),
    );
  }

  /// Converts the `Studentmodel` instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gender': gender,
      'grade': grade,
      'dateofadd': dateofadd,
      'note': note,
      'name': name,
      'fatherphone': fatherPhone,
      'mothernumber': motherPhone,
      'phonenumber': phoneNumber,
      'numberOfAbsentDays': numberOfAbsentDays,
      'numberOfAttendantDays': numberOfAttendantDays,
      'lastDayStudentCame': lastDayStudentCame,
      'lastDateStudentCame': lastDateStudentCame,
      'hisGroups': hisGroups?.map((group) => group.toJson()).toList(),
      'hisGroupsId': hisGroupsId,
      'absencesNumbers': absencesNumbers?.map((abs) => abs.toJson()).toList(),
      'studentPaidSubscriptions':
          studentPaidSubscriptions?.map((sub) => sub.toJson()).toList(),
    };
  }
}
