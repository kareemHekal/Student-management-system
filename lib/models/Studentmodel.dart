import 'package:flutter/material.dart';

class Studentmodel {
  String id;
  String? name;
  String? grade;
  String? firstDayId;
  String? forthdayid;
  String? forthday;
  TimeOfDay? forthdayTime;
  String? firstDay;
  TimeOfDay? firstDayTime;
  String? secondDay;
  String? secondDayId;
  TimeOfDay? secondDayTime;
  String? thirdDay;
  String? thirdDayId;
  TimeOfDay? thirdDayTime;
  String? gender;
  String? phoneNumber;
  String? motherPhone;
  String? fatherPhone;
  bool? firstMonth;
  bool? secondMonth;
  bool? thirdMonth;
  bool? fourthMonth;
  bool? fifthMonth;
  bool? explainingNote;
  bool? reviewNote;
  String? note;
  String? dateofadd;
  int? numberOfAbsentDays;
  int? numberOfAttendantDays;
  String? lastDayStudentCame;
  String? lastDateStudentCame;

  String? dateOfFirstMonthPaid;
  String? dateOfSecondMonthPaid;
  String? dateOfThirdMonthPaid;
  String? dateOfFourthMonthPaid;
  String? dateOfFifthMonthPaid;

  Studentmodel({
    this.id = "",
    this.grade,
    this.thirdDayId,
    this.firstDayId,
    this.secondDayId,
    this.name,
    this.firstDay,
    this.firstDayTime,
    this.secondDay,
    this.secondDayTime,
    this.thirdDay,
    this.thirdDayTime,
    this.gender,
    this.explainingNote,
    this.reviewNote,
    this.phoneNumber,
    this.motherPhone,
    this.fatherPhone,
    this.firstMonth,
    this.secondMonth,
    this.thirdMonth,
    this.fourthMonth,
    this.fifthMonth,
    this.forthdayid,
    this.forthday,
    this.forthdayTime,
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
  });

  factory Studentmodel.fromJson(Map<String, dynamic> json) {
    return Studentmodel(
      id: json['id'] ?? "",
      name: json['name'],
      note: json['note'],
      dateofadd: json['dateofadd'],
      gender: json['gender'],
      firstDayId: json['firstdayid'],
      secondDayId: json['seconddayid'],
      thirdDayId: json['thirddayid'],
      firstDay: json["firstDay"],
      grade: json['grade'],
      fatherPhone: json['fatherphone'],
      firstMonth: json['firstmonth'],
      secondMonth: json['secondmonth'],
      thirdMonth: json['thirdmonth'],
      fourthMonth: json['fourthmonth'],
      fifthMonth: json['fifthMonth'],
      motherPhone: json['mothernumber'],
      phoneNumber: json['phonenumber'],
      explainingNote: json['explainingnote'],
      reviewNote: json['reviewnote'],
      firstDayTime: json['firstdaytime'] != null
          ? TimeOfDay(
        hour: json['firstdaytime']['hour'] ?? 0,
        minute: json['firstdaytime']['minute'] ?? 0,
      )
          : null,
      secondDay: json['secondday'],
      secondDayTime: json['seconddaytime'] != null
          ? TimeOfDay(
        hour: json['seconddaytime']['hour'] ?? 0,
        minute: json['seconddaytime']['minute'] ?? 0,
      )
          : null,
      thirdDay: json['thirdday'],
      thirdDayTime: json['thirddaytime'] != null
          ? TimeOfDay(
        hour: json['thirddaytime']['hour'] ?? 0,
        minute: json['thirddaytime']['minute'] ?? 0,
      )
          : null,
      forthdayid: json['forthdayid'],
      forthday: json['forthday'],
      forthdayTime: json['forthdaytime'] != null
          ? TimeOfDay(
        hour: json['forthdaytime']['hour'] ?? 0,
        minute: json['forthdaytime']['minute'] ?? 0,
      )
          : null,
      numberOfAbsentDays: json['numberOfAbsentDays'],
      numberOfAttendantDays: json['numberOfAttendantDays'],
      lastDayStudentCame: json['lastDayStudentCame'],
      lastDateStudentCame: json['lastDateStudentCame'],
      dateOfFirstMonthPaid: json['dateOfFirstMonthPaid'],
      dateOfSecondMonthPaid: json['dateOfSecondMonthPaid'],
      dateOfThirdMonthPaid: json['dateOfThirdMonthPaid'],
      dateOfFourthMonthPaid: json['dateOfFourthMonthPaid'],
      dateOfFifthMonthPaid: json['dateOfFifthMonthPaid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gender': gender,
      'grade': grade,
      'dateofadd': dateofadd,
      'note': note,
      'name': name,
      'firstdayid': firstDayId,
      'seconddayid': secondDayId,
      'thirddayid': thirdDayId,
      'fatherphone': fatherPhone,
      'firstmonth': firstMonth,
      'secondmonth': secondMonth,
      'thirdmonth': thirdMonth,
      'fourthmonth': fourthMonth,
      'fifthMonth': fifthMonth,
      'mothernumber': motherPhone,
      "firstDay": firstDay,
      'phonenumber': phoneNumber,
      'explainingnote': explainingNote,
      'reviewnote': reviewNote,
      'firstdaytime': firstDayTime != null
          ? {'hour': firstDayTime!.hour, 'minute': firstDayTime!.minute}
          : null,
      'secondday': secondDay,
      'seconddaytime': secondDayTime != null
          ? {'hour': secondDayTime!.hour, 'minute': secondDayTime!.minute}
          : null,
      'thirdday': thirdDay,
      'thirddaytime': thirdDayTime != null
          ? {'hour': thirdDayTime!.hour, 'minute': thirdDayTime!.minute}
          : null,
      'forthdayid': forthdayid,
      'forthday': forthday,
      'forthdaytime': forthdayTime != null
          ? {'hour': forthdayTime!.hour, 'minute': forthdayTime!.minute}
          : null,
      'numberOfAbsentDays': numberOfAbsentDays,
      'numberOfAttendantDays': numberOfAttendantDays,
      'lastDayStudentCame': lastDayStudentCame,
      'lastDateStudentCame': lastDateStudentCame,
      'dateOfFirstMonthPaid': dateOfFirstMonthPaid,
      'dateOfSecondMonthPaid': dateOfSecondMonthPaid,
      'dateOfThirdMonthPaid': dateOfThirdMonthPaid,
      'dateOfFourthMonthPaid': dateOfFourthMonthPaid,
      'dateOfFifthMonthPaid': dateOfFifthMonthPaid,
    };
  }
}
