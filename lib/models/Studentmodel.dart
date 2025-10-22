import 'Magmo3aModel.dart';
import 'absence_model.dart';

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

  // List of groups and absences
  List<Magmo3amodel>? hisGroups;
  List<String>? hisGroupsId;
  List<AbsenceModel>? absencesNumbers;

  // Flags for tracking payments and notes
  bool? firstMonth;
  bool? secondMonth;
  bool? thirdMonth;
  bool? fourthMonth;
  bool? fifthMonth;
  bool? explainingNote;
  bool? reviewNote;

  // Additional student information
  String? note;
  String? dateofadd;
  int? numberOfAbsentDays;
  int? numberOfAttendantDays;
  String? lastDayStudentCame;
  String? lastDateStudentCame;

  // Dates for payments
  String? dateOfFirstMonthPaid;
  String? dateOfSecondMonthPaid;
  String? dateOfThirdMonthPaid;
  String? dateOfFourthMonthPaid;
  String? dateOfFifthMonthPaid;
  String? dateOfExplainingNotePaid;
  String? dateOfReviewingNotePaid;

  Studentmodel({
    this.id = "",
    this.hisGroups,
    this.hisGroupsId,
    this.grade,
    this.name,
    this.gender,
    this.explainingNote,
    this.reviewNote,
    this.phoneNumber,
    this.absencesNumbers,
    this.motherPhone,
    this.fatherPhone,
    this.firstMonth,
    this.secondMonth,
    this.thirdMonth,
    this.fourthMonth,
    this.fifthMonth,
    this.note,
    this.dateofadd,
    this.numberOfAbsentDays,
    this.numberOfAttendantDays,
    this.lastDayStudentCame,
    this.lastDateStudentCame,
    this.dateOfFirstMonthPaid,
    this.dateOfSecondMonthPaid,
    this.dateOfThirdMonthPaid,
    this.dateOfFourthMonthPaid,
    this.dateOfFifthMonthPaid,
    this.dateOfExplainingNotePaid,
    this.dateOfReviewingNotePaid,
  });

  /// Factory method to create a `Studentmodel` instance from a JSON object.
  factory Studentmodel.fromJson(Map<String, dynamic> json) {
    return Studentmodel(
      id: json['id'] ?? "",
      name: json['name'],
      motherPhone: json['mothernumber'],
      phoneNumber: json['phonenumber'],
      explainingNote: json['explainingnote'],
      reviewNote: json['reviewnote'],
      note: json['note'],
      dateofadd: json['dateofadd'],
      gender: json['gender'],
      grade: json['grade'],
      fatherPhone: json['fatherphone'],
      firstMonth: json['firstmonth'],
      secondMonth: json['secondmonth'],
      thirdMonth: json['thirdmonth'],
      fourthMonth: json['fourthmonth'],
      fifthMonth: json['fifthMonth'],
      numberOfAbsentDays: json['numberOfAbsentDays'],
      numberOfAttendantDays: json['numberOfAttendantDays'],
      lastDayStudentCame: json['lastDayStudentCame'],
      lastDateStudentCame: json['lastDateStudentCame'],
      dateOfFirstMonthPaid: json['dateOfFirstMonthPaid'],
      dateOfSecondMonthPaid: json['dateOfSecondMonthPaid'],
      dateOfThirdMonthPaid: json['dateOfThirdMonthPaid'],
      dateOfFourthMonthPaid: json['dateOfFourthMonthPaid'],
      dateOfFifthMonthPaid: json['dateOfFifthMonthPaid'],
      dateOfExplainingNotePaid: json['dateOfExplainingNotePaid'],
      dateOfReviewingNotePaid: json['dateOfReviewingNotePaid'],
      // Convert JSON list to `hisGroups`
      hisGroups: (json['hisGroups'] as List<dynamic>?)
          ?.map((group) => Magmo3amodel.fromJson(group))
          .toList(),
      hisGroupsId: (json['hisGroupsId'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList(),
      // Convert JSON list to `absencesNumbers`
      absencesNumbers: (json['absencesNumbers'] as List<dynamic>?)
          ?.map((item) => AbsenceModel.fromJson(item))
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
      'firstmonth': firstMonth,
      'secondmonth': secondMonth,
      'thirdmonth': thirdMonth,
      'fourthmonth': fourthMonth,
      'fifthMonth': fifthMonth,
      'mothernumber': motherPhone,
      'phonenumber': phoneNumber,
      'explainingnote': explainingNote,
      'reviewnote': reviewNote,
      'numberOfAbsentDays': numberOfAbsentDays,
      'numberOfAttendantDays': numberOfAttendantDays,
      'lastDayStudentCame': lastDayStudentCame,
      'lastDateStudentCame': lastDateStudentCame,
      'dateOfFirstMonthPaid': dateOfFirstMonthPaid,
      'dateOfSecondMonthPaid': dateOfSecondMonthPaid,
      'dateOfThirdMonthPaid': dateOfThirdMonthPaid,
      'dateOfFourthMonthPaid': dateOfFourthMonthPaid,
      'dateOfFifthMonthPaid': dateOfFifthMonthPaid,
      'dateOfExplainingNotePaid': dateOfExplainingNotePaid,
      'dateOfReviewingNotePaid': dateOfReviewingNotePaid,
      'hisGroups': hisGroups?.map((group) => group.toJson()).toList(),
      'hisGroupsId': hisGroupsId,
      'absencesNumbers': absencesNumbers?.map((abs) => abs.toJson()).toList(),
    };
  }
}
