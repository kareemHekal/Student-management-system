import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/models/absence_app/absence_model.dart';
import 'package:student_management_system/models/absence_app/secondary_record.dart';
import 'package:student_management_system/models/admin/bill.dart';
import 'package:student_management_system/models/admin/boost_subscription.dart';
import 'package:student_management_system/models/admin/subsription.dart';
import 'package:student_management_system/models/admin/teacher.dart';
import 'package:student_management_system/pages/payment/easy_cash_service.dart';
import 'package:student_management_system/provider.dart';
import 'package:student_management_system/theme/snack_bar.dart';

import '../models/invoice.dart';
import '../models/Magmo3aModel.dart';
import '../models/Student_model.dart';
import '../models/absence_app/student_absence_model.dart';
import '../models/daily_invoice.dart';
import '../models/grade_subscriptions_model.dart';
import '../models/payment.dart';
import '../models/subscription_fee.dart';
import 'exams_functions.dart';

class FirebaseFunctions {
  static final _db = FirebaseFirestore.instance;

  // دالة المساعدة الأساسية للحصول على مسار المدرس الحالي
  static String get teacherPath {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("لا يوجد مدرس مسجل دخول!");
    return 'teachers/${user.uid}';
  }

  // =============================== Magmo3a Functions ===============================

  /// Adds a `Magmo3aModel` to a specific day's collection

  static Future<void> addMagmo3aToDay(String day, Magmo3amodel magmo3a) async {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);

    // Generate a new document reference and set its ID
    DocumentReference<Magmo3amodel> newDocRef = dayCollection.doc();
    magmo3a.id = newDocRef.id;

    // Save the document in Firestore
    await newDocRef.set(magmo3a);
  }

  static Future<void> editMagmo3aInDay(
    String oldDay,
    String oldGrade,
    Magmo3amodel updatedMagmo3a,
  ) async {
    final newDay = updatedMagmo3a.day;

    // 🧩 1️⃣ نقل المجموعة لو اليوم اتغير
    if (newDay != oldDay) {
      final oldDayCollection = getDayCollection(oldDay);
      await oldDayCollection.doc(updatedMagmo3a.id).delete();

      final newDayCollection = getDayCollection(newDay!);
      await newDayCollection.doc(updatedMagmo3a.id).set(updatedMagmo3a);
    } else {
      final dayCollection = getDayCollection(newDay!);
      await dayCollection.doc(updatedMagmo3a.id).set(updatedMagmo3a);
    }

    // 🧩 2️⃣ جلب الطلاب (دلوقتي دي بقت List مباشرة مش Snapshot)
    final studentsList = await getStudentsByGroupId_future(
      oldGrade,
      updatedMagmo3a.id,
    );

    // 🧩 3️⃣ تحديث بيانات المجموعة جوه كل طالب
    for (var student in studentsList) {
      bool isChanged = false;

      if (student.hisGroups != null) {
        for (int i = 0; i < student.hisGroups!.length; i++) {
          // لو لقينا المجموعة القديمة بنحدثها بالجديدة
          if (student.hisGroups![i].id == updatedMagmo3a.id) {
            student.hisGroups![i] = updatedMagmo3a;
            isChanged = true;
          }
        }
      }

      // بنعمل Update فقط لو الطالب فعلاً اتأثر بالتعديل
      if (isChanged) {
        await getSecondaryCollection(oldGrade).doc(student.id).update({
          "hisGroups": student.hisGroups!.map((g) => g.toJson()).toList(),
        });
      }
    }
  }

  static Future<void> deleteMagmo3aFromDay({
    required String day,
    required String grade,
    required String magmo3aId,
  }) async {
    try {
      // 1️⃣ حذف الـ Sub-collection (absences) أولاً
      final absenceCollection =
          getDayCollection(day).doc(magmo3aId).collection('absences');

      final absenceSnapshot = await absenceCollection.get();

      if (absenceSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in absenceSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print("✅ Absences sub-collection deleted.");
      }

      // 2️⃣ حذف المجموعة نفسها من جدول الأيام
      await getDayCollection(day).doc(magmo3aId).delete();
      print("✅ Magmo3a document deleted.");

      // 3️⃣ تنظيف بيانات الطلاب
      List<Studentmodel> allStudents =
          await getAllStudentsByGrade_future(grade);

      final studentBatch = _db.batch();
      bool needsUpdate = false;

      for (var student in allStudents) {
        bool studentChanged = false;

        if (student.hisGroupsId != null &&
            student.hisGroupsId!.contains(magmo3aId)) {
          student.hisGroupsId!.remove(magmo3aId);
          studentChanged = true;
        }

        if (student.hisGroups != null) {
          int initialLength = student.hisGroups!.length;
          student.hisGroups!.removeWhere((group) => group.id == magmo3aId);
          if (student.hisGroups!.length != initialLength) {
            studentChanged = true;
          }
        }

        if (studentChanged) {
          final studentRef = getSecondaryCollection(grade).doc(student.id);
          studentBatch.update(studentRef, student.toJson());
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        await studentBatch.commit();
        print("✅ Updated students: Removed deleted group from their profiles.");
      }

      print("🎉 Cleanup complete for Magmo3a: $magmo3aId");
    } catch (e) {
      print("❌ Error during deleteMagmo3a: $e");
      rethrow;
    }
  }

  static Stream<List<Magmo3amodel>> getAllDocsFromDay(String day) {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);
    return dayCollection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Stream<List<Magmo3amodel>> getAllDocsFromDayWithGrade(
      String day, String grade) {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);

    return dayCollection
        .where("grade", isEqualTo: grade)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Future<void> deleteAbsencesSubCollection(String day) async {
    try {
      // التعديل: استخدام getDayCollection للتأكد من المسار الجديد للمدرس
      QuerySnapshot daySnapshot = await getDayCollection(day).get();

      for (var groupDoc in daySnapshot.docs) {
        CollectionReference absencesSubcollectionRef =
            groupDoc.reference.collection('absences');

        QuerySnapshot absencesSnapshot = await absencesSubcollectionRef.get();
        for (var absenceDoc in absencesSnapshot.docs) {
          await absenceDoc.reference.delete();
        }
      }
    } catch (e) {
      print("Error deleting absences subcollection: $e");
    }
  }

  static CollectionReference<Magmo3amodel> getDayCollection(String day) {
    // التصحيح: بنبدأ بـ doc للمدرس، وبعدين نفتح جواه الـ collection بتاع اليوم
    return _db
        .doc(teacherPath) // ده الـ Document بتاع المدرس
        .collection(day) // ده الـ Sub-collection اللي جواه
        .withConverter<Magmo3amodel>(
          fromFirestore: (snapshot, _) =>
              Magmo3amodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        );
  }

  // =============================== Student Functions ===============================

  // =============================== Student Management ===============================

  static Future<void> saveMonthAndStartNew(String monthName) async {
    try {
      final grades = await FirebaseFunctions.getGradesList();

      await Future.wait(grades.map((grade) async {
        final collection = getSecondaryCollection(grade);
        final snapshot = await collection.get();

        if (snapshot.docs.isEmpty) return;

        final studentDocs = snapshot.docs;
        const batchLimit = 500;

        for (var i = 0; i < studentDocs.length; i += batchLimit) {
          final batch = _db.batch();
          final chunk = studentDocs.skip(i).take(batchLimit);

          for (final doc in chunk) {
            final student = doc.data();

            final newAbsence = StudentAbsencesModel(
              monthName: monthName,
              attendedDays: student.countingAttendedDays ?? [],
              absentDays: student.countingAbsentDays ?? [],
            ).toJson();

            batch.update(doc.reference, {
              'absencesNumbers': FieldValue.arrayUnion([newAbsence]),
              'countingAttendedDays': [],
              'countingAbsentDays': [],
            });
          }
          await batch.commit();
        }
      }));
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> resetGradeData({
    required String gradeName,
    required List<String> daysList,
    required bool resetSubscriptions,
    required bool resetAbsence,
    required bool deleteExams,
    required bool deleteGroups,
    required bool deleteStudents,
    required bool deleteInvoices,
  }) async {
    try {
      if (deleteInvoices) {
        final invoicesSnap =
            await _db.doc(teacherPath).collection('big_invoices').get();

        final invoiceBatch = _db.batch();
        for (var doc in invoicesSnap.docs) {
          invoiceBatch.delete(doc.reference);
        }
        await invoiceBatch.commit();

        // نغير القيمة لـ false عشان ميتكررش الحذف مع كل مرحلة لو مختار أكتر من مرحلة
        deleteInvoices = false;
      }

      // 1. مسح اشتراكات المرحلة - المسار الجديد داخل ثابت المدرس
      if (resetSubscriptions && gradeName.isNotEmpty) {
        await _db
            .doc(teacherPath)
            .collection('constants')
            .doc('grades_subscriptions')
            .collection('grades')
            .doc(gradeName)
            .update({'subscriptions': []});
      }

      // --- 3. معالجة الطلاب (فقط إذا تم اختيار مرحلة) ---
      if (gradeName.isNotEmpty) {
        final allStudents = await getAllStudentsByGrade_future(gradeName);
        const batchSize = 400;

        for (int i = 0; i < allStudents.length; i += batchSize) {
          final batch = _db.batch();
          final chunk = allStudents.skip(i).take(batchSize);

          for (final student in chunk) {
            final studentRef =
                getSecondaryCollection(gradeName).doc(student.id);

            if (deleteStudents) {
              batch.delete(studentRef);
            } else {
              Map<String, dynamic> updates = {};
              if (resetSubscriptions) updates['studentPaidSubscriptions'] = [];
              if (resetAbsence) {
                updates['absencesNumbers'] = [];
                updates['countingAttendedDays'] = [];
                updates['countingAbsentDays'] = [];
              }
              if (deleteExams) updates['studentExamsGrades'] = [];

              if (updates.isNotEmpty) batch.update(studentRef, updates);
            }
          }
          await batch.commit();
        }
        // 3. حذف الامتحانات من مسار المدرس
        if (deleteExams) {
          await _db
              .doc(teacherPath)
              .collection('exams')
              .doc(gradeName)
              .delete();
        }

        for (String day in daysList) {
          if (deleteGroups) {
            final groupSnap = await getDayCollection(day)
                .where('grade', isEqualTo: gradeName)
                .get();

            final groupBatch = _db.batch();
            for (var doc in groupSnap.docs) {
              groupBatch.delete(doc.reference);
            }
            await groupBatch.commit();
          }

          if (resetAbsence) {
            await deleteAbsencesSubCollection(day);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a `StudentModel` and increments the teacher's total student count
  static Future<String> addStudentToCollection(
      String grade, Studentmodel studentModel) async {
    // 1. المرجع بتاع الطالب
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);
    DocumentReference<Studentmodel> newDocRef = collection.doc();
    studentModel.id = newDocRef.id;

    // 2. مرجع دوكيومنت المدرس لتحديث العداد
    DocumentReference teacherDoc = _db.doc(teacherPath);

    // بنستخدم Batch عشان نضمن إن الطالب يتضاف والعداد يزيد مع بعض (أو لا قدر الله لو فشل واحد التاني ميتعملش)
    WriteBatch batch = _db.batch();

    batch.set(newDocRef, studentModel);
    batch.update(teacherDoc, {
      'currentStudentCount': FieldValue.increment(1), // بيزود العداد 1
    });

    await batch.commit();
    return newDocRef.id;
  }

  /// Deletes a `StudentModel` and decrements the teacher's total student count
  static Future<void> deleteStudentFromHisCollection(
      String grade, String documentId) async {
    DocumentReference studentDoc =
        getSecondaryCollection(grade).doc(documentId);
    DocumentReference teacherDoc = _db.doc(teacherPath);

    WriteBatch batch = _db.batch();

    batch.delete(studentDoc);
    batch.update(teacherDoc, {
      'currentStudentCount': FieldValue.increment(-1), // بينقص العداد 1
    });

    await batch.commit();
  }

  static Future<void> moveStudentToNewGrade({
    required Studentmodel student,
    required String oldGrade,
    required String newGrade,
  }) async {
    // 1. تجهيز بيانات الطالب الجديدة (تغيير الصف وتصفير السجلات)
    student.grade = newGrade;
    student.hisGroups = [];
    student.hisGroupsId = [];
    student.absencesNumbers = [];
    student.studentPaidSubscriptions = [];
    student.studentExamsGrades = [];
    student.countingAttendedDays = [];
    student.countingAbsentDays = [];
    student.notes = [];
    student.note = "";

    WriteBatch batch = _db.batch();

    // 2. مرجع المكان القديم (حذف)
    DocumentReference oldDocRef =
        getSecondaryCollection(oldGrade).doc(student.id);
    batch.delete(oldDocRef);

    // 3. مرجع المكان الجديد (إضافة) - سنعطيه ID جديد تلقائي
    DocumentReference<Studentmodel> newDocRef =
        getSecondaryCollection(newGrade).doc();
    student.id = newDocRef.id; // تحديث الـ ID داخل الموديل
    batch.set(newDocRef, student);

    // ملحوظة: العداد (StudentCount) لن يتغير لأننا حذفنا 1 وأضفنا 1
    // فلا داعي لتحديث teacherDoc إلا لو كنت تريد التأكد تماماً

    await batch.commit();
  }

  static Future<void> updateStudentInCollection(
      String grade, String studentId, Studentmodel updatedStudentModel) async {
    await getSecondaryCollection(grade)
        .doc(studentId)
        .update(updatedStudentModel.toJson());
  }

  // 1. جلب كل طلاب المرحلة (Future) - موفر جداً
  static Future<List<Studentmodel>> getAllStudentsByGrade_future(
      String grade) async {
    // بنحدد إننا عايزين الداتا من الـ Cache والسيرفر بذكاء
    QuerySnapshot<Studentmodel> snapshot = await getSecondaryCollection(grade)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

// 2. جلب طلاب مجموعة معينة (Future) - ممتاز للطباعة والبحث
  static Future<List<Studentmodel>> getStudentsByGroupId_future(
      String grade, String groupId) async {
    QuerySnapshot<Studentmodel> snapshot = await getSecondaryCollection(grade)
        .where("hisGroupsId", arrayContains: groupId)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

// الـ CollectionReference زي ما هو
  static CollectionReference<Studentmodel> getSecondaryCollection(
      String grade) {
    return _db.doc(teacherPath).collection(grade).withConverter<Studentmodel>(
          fromFirestore: (snapshot, _) =>
              Studentmodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        );
  }

  static Future<void> addGradeToList(String newGrade) async {
    try {
      // تعديل المسار: الثوابت بقت خاصة بكل مدرس
      final gradesDoc =
          _db.doc(teacherPath).collection('constants').doc('grades');

      final snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> gradesList = List.from(data['grades'] ?? []);
        if (!gradesList.contains(newGrade)) {
          gradesList.add(newGrade);
          await gradesDoc.update({'grades': gradesList});
        }
      } else {
        await gradesDoc.set({
          'grades': [newGrade]
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  static Future<void> deleteGradeFromList(String grade) async {
    try {
      // التعديل: الوصول لمسار المدرس ثم constants ثم doc(grades)
      DocumentReference gradesDoc =
          _db.doc(teacherPath).collection('constants').doc('grades');

      DocumentSnapshot snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        List<dynamic> gradesList = snapshot['grades'];
        gradesList.remove(grade);
        await gradesDoc.update({'grades': gradesList});
        print("Grade removed successfully.");
      }
    } catch (e) {
      print("Error deleting grade: $e");
    }
  }

  static Future<List<String>> getGradesList() async {
    try {
      // التعديل: أضفنا GetOptions مع Source.serverAndCache
      // دي بتخلي الفايربيز يشوف الموبايل الأول، ولو مفيش تغيير ميسحبش Reads
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await _db
          .doc(teacherPath)
          .collection('constants')
          .doc('grades')
          .get(const GetOptions(source: Source.serverAndCache));

      if (docSnapshot.exists) {
        List<dynamic> gradesDynamic = docSnapshot.data()?['grades'] ?? [];
        return gradesDynamic.map((grade) => grade.toString()).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching grades: $e");
      return [];
    }
  }

  static Future<void> renameGrade(String oldGrade, String newGrade) async {
    try {
      final fireStore = _db;
      // المسار المختصر للمدرس
      final teacherDocRef = fireStore.doc(teacherPath);

      // 1️⃣ Update grade name in constants/grades list (خاص بالمدرس)
      final DocumentReference gradesDoc =
          teacherDocRef.collection('constants').doc('grades');
      final gradesSnapshot = await gradesDoc.get();

      if (gradesSnapshot.exists) {
        List<dynamic> gradesList = List.from(gradesSnapshot['grades']);
        if (gradesList.contains(oldGrade)) {
          int index = gradesList.indexOf(oldGrade);
          gradesList[index] = newGrade;
          await gradesDoc.update({'grades': gradesList});
        }
      }

      // 2️⃣ Move Students (المسارات متعدلة أوتوماتيك داخل getSecondaryCollection)
      final oldCollection = getSecondaryCollection(oldGrade);
      final newCollection = getSecondaryCollection(newGrade);
      final oldStudentsSnapshot = await oldCollection.get();

      if (oldStudentsSnapshot.docs.isNotEmpty) {
        WriteBatch studentBatch = fireStore.batch();
        int count = 0;

        for (var doc in oldStudentsSnapshot.docs) {
          Studentmodel student = doc.data();
          student.grade = newGrade;

          if (student.hisGroups != null) {
            for (var group in student.hisGroups!) {
              if (group.grade == oldGrade) {
                group.grade = newGrade;
              }
            }
          }

          studentBatch.set(newCollection.doc(student.id), student);
          studentBatch.delete(doc.reference);

          count++;
          if (count >= 450) {
            await studentBatch.commit();
            studentBatch = fireStore.batch();
            count = 0;
          }
        }
        if (count > 0) await studentBatch.commit();
      }

      // 3️⃣ Update Magmo3a documents (المسارات متعدلة داخل getDayCollection)
      final allDays = [
        "Saturday",
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday"
      ];
      await Future.wait(allDays.map((day) async {
        final dayCollection = getDayCollection(day);
        final daySnapshot =
            await dayCollection.where('grade', isEqualTo: oldGrade).get();

        if (daySnapshot.docs.isNotEmpty) {
          final dayBatch = fireStore.batch();
          for (var doc in daySnapshot.docs) {
            Magmo3amodel magmo3a = doc.data();
            magmo3a.grade = newGrade;
            dayBatch.set(dayCollection.doc(magmo3a.id), magmo3a);
          }
          await dayBatch.commit();
        }
      }));

      // 4️⃣ Rename Grade Subscription & Exams (تحت مسار المدرس)
      final batchFinal = fireStore.batch();

      final oldSubRef = teacherDocRef
          .collection('constants')
          .doc('grades_subscriptions')
          .collection('grades')
          .doc(oldGrade);

      final newSubRef = teacherDocRef
          .collection('constants')
          .doc('grades_subscriptions')
          .collection('grades')
          .doc(newGrade);

      final subSnap = await oldSubRef.get();
      if (subSnap.exists) {
        final oldModel = GradeSubscriptionsModel.fromJson(subSnap.data()!);
        oldModel.gradeName = newGrade;
        batchFinal.set(newSubRef, oldModel.toJson());
        batchFinal.delete(oldSubRef);
      }

      final oldExamRef = teacherDocRef.collection('exams').doc(oldGrade);
      final newExamRef = teacherDocRef.collection('exams').doc(newGrade);
      final examSnap = await oldExamRef.get();

      if (examSnap.exists) {
        final examData = Map<String, dynamic>.from(examSnap.data()!);
        examData['gradeName'] = newGrade;
        batchFinal.set(newExamRef, examData);
        batchFinal.delete(oldExamRef);
      }
      await batchFinal.commit();

      // 5️⃣ Update Grade in "big_invoices" collection (تحت مسار المدرس)
      final bigInvoicesCollection = teacherDocRef.collection('big_invoices');
      final invoicesSnapshot = await bigInvoicesCollection.get();

      if (invoicesSnapshot.docs.isNotEmpty) {
        WriteBatch invoiceBatch = fireStore.batch();
        int invCount = 0;

        for (var doc in invoicesSnapshot.docs) {
          Map<String, dynamic> data = doc.data();
          List<dynamic> invoicesJson = data['invoices'] as List? ?? [];
          bool docNeedsUpdate = false;

          for (var inv in invoicesJson) {
            if (inv['grade'] == oldGrade) {
              inv['grade'] = newGrade;
              docNeedsUpdate = true;
            }
          }

          if (docNeedsUpdate) {
            invoiceBatch.update(doc.reference, {'invoices': invoicesJson});
            invCount++;
            if (invCount >= 450) {
              await invoiceBatch.commit();
              invoiceBatch = fireStore.batch();
              invCount = 0;
            }
          }
        }
        if (invCount > 0) await invoiceBatch.commit();
      }
    } catch (e) {
      rethrow;
    }
  }

  static Stream<List<String>> getGradesStream() {
    return _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades')
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists) {
        List<dynamic> gradesDynamic = docSnapshot.data()?['grades'] ?? [];
        return gradesDynamic.map((grade) => grade.toString()).toList();
      }
      return [];
    });
  }

  //=============================== BigInvoices Functions ===============================
  // =============================== Invoices & Payments (Sub-collections) ===============================

  static Future<void> createBigInvoiceCollection() async {
    // التعديل: إنشاء الكولكشن داخل مسار المدرس
    CollectionReference bigInvoicesCollection =
        _db.doc(teacherPath).collection('big_invoices');

    await bigInvoicesCollection.doc('dummy').set({'dummyField': 'dummyValue'});
  }

  static Future<void> deleteBigInvoiceCollection() async {
    // التعديل: الوصول للكولكشن الخاص بالمدرس
    CollectionReference bigInvoicesCollection =
        _db.doc(teacherPath).collection('big_invoices');

    QuerySnapshot snapshot = await bigInvoicesCollection.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Stream invoices ordered by date descending, with a limit to prevent
  /// loading years of history at once. Pass [limit] to control how many
  /// daily-invoice docs to load (default: 90 days ~= 3 months).
  static Stream<QuerySnapshot> getAllBigInvoices({int limit = 90}) {
    return _db
        .doc(teacherPath)
        .collection('big_invoices')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Paginated one-time fetch for older invoices (load-more pattern).
  static Future<QuerySnapshot> getOlderBigInvoices({
    required String beforeDate,
    int limit = 30,
  }) {
    return _db
        .doc(teacherPath)
        .collection('big_invoices')
        .orderBy(FieldPath.documentId, descending: true)
        .startAfter([beforeDate])
        .limit(limit)
        .get();
  }

  static Future<void> updateDailyInvoice(
      String date, DailyInvoice bigInvoice) async {
    CollectionReference invoicesCollection =
        _db.doc(teacherPath).collection('big_invoices');

    DocumentSnapshot docSnapshot = await invoicesCollection.doc(date).get();

    if (docSnapshot.exists) {
      await invoicesCollection.doc(date).update(bigInvoice.toJson());
    } else {
      await invoicesCollection.doc(date).set(bigInvoice.toJson());
    }
  }

  static Future<void> addPaymentToFirestore({
    required String date,
    required String day,
    required String amountText,
    required String description,
  }) async {
    // التعديل: المسار أصبح تحت المدرس
    final docRef = _db.doc(teacherPath).collection('big_invoices').doc(date);

    final docSnapshot = await docRef.get();

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null && amountText != '0') {
      throw Exception("Invalid amount: $amountText");
    }

    final newPayment = Payment(
      amount: parsedAmount ?? 0.0,
      description: description.trim(),
      dateTime: DateTime.now(),
    );

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data == null) throw Exception("Document data is null for $date");
      final bigInvoice = DailyInvoice.fromJson(data);
      bigInvoice.payments.add(newPayment);
      await docRef.update(bigInvoice.toJson());
    } else {
      final bigInvoice = DailyInvoice(
        date: date,
        day: day,
        invoices: [],
        payments: [newPayment],
      );
      await docRef.set(bigInvoice.toJson());
    }
  }

  static Future<void> updatePaymentInBigInvoice({
    required String date,
    required Payment updatedPayment,
    required int paymentIndex,
  }) async {
    CollectionReference invoicesCollection =
        _db.doc(teacherPath).collection('big_invoices');

    DocumentSnapshot docSnapshot = await invoicesCollection.doc(date).get();

    if (!docSnapshot.exists) {
      throw Exception("Document with date $date does not exist");
    }

    final rawData = docSnapshot.data();
    if (rawData == null) throw Exception("Document data is null for $date");
    Map<String, dynamic> data = rawData as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    if (paymentIndex < 0 || paymentIndex >= bigInvoice.payments.length) {
      throw Exception("Invalid payment index");
    }
    bigInvoice.payments[paymentIndex] = updatedPayment;

    await invoicesCollection.doc(date).update(bigInvoice.toJson());
  }

  // ✅ تعديل جلب الـ ID التسلسلي ليكون خاص بكل مدرس
  // Uses FieldValue.increment which is atomic server-side (no transaction needed,
  // no contention, no retries). Much cheaper at scale.
  static Future<int> getAndIncrementInvoiceId() async {
    DocumentReference docRef =
        _db.doc(teacherPath).collection('constants').doc('bills_ids');

    // Atomic increment (server-side) — single write, no read-then-write conflict
    await docRef.set(
      {'bills_ids': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    // Read the new value
    final snapshot = await docRef.get();
    final data = snapshot.data() as Map<String, dynamic>?;
    return (data?['bills_ids'] ?? 1) as int;
  }

  static Future<void> addInvoiceToBigInvoices({
    required String date,
    required String day,
    required String grade,
    required double amount,
    required String subscriptionFeeID,
    required String description,
    required String studentId,
    required String studentName,
    required String phoneNumber,
    required String motherPhone,
    required String fatherPhone,
  }) async {
    int invoiceId = await getAndIncrementInvoiceId();

    Invoice newInvoice = Invoice(
      id: invoiceId.toString(),
      studentId: studentId,
      studentName: studentName,
      subscriptionFeeID: subscriptionFeeID,
      studentPhoneNumber: phoneNumber,
      momPhoneNumber: motherPhone,
      dadPhoneNumber: fatherPhone,
      grade: grade,
      amount: amount,
      description: description,
      dateTime: DateTime.now(),
    );

    // التعديل: الفاتورة تحفظ في مسار المدرس
    DocumentReference docRef =
        _db.doc(teacherPath).collection('big_invoices').doc(date);

    try {
      await docRef.set({
        'date': date,
        'day': day,
        'invoices': FieldValue.arrayUnion([newInvoice.toJson()]),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateInvoiceInBigInvoices({
    required String date,
    required double differenceAmount,
    required Invoice updatedInvoice,
  }) async {
    final docRef = _db.doc(teacherPath).collection('big_invoices').doc(date);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception("BigInvoice for $date not found");
    }

    final rawData = docSnapshot.data();
    if (rawData == null) throw Exception("BigInvoice data is null for $date");
    Map<String, dynamic> data = rawData as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    int index = bigInvoice.invoices
        .indexWhere((invoice) => invoice.id == updatedInvoice.id);

    if (index == -1) throw Exception("Invoice not found");

    bigInvoice.invoices[index] = updatedInvoice;

    Studentmodel? student = await FirebaseExams.getStudent(
      updatedInvoice.grade,
      updatedInvoice.studentId,
    );

    // Atomic batch: update invoice AND student paidAmount together
    final batch = _db.batch();
    batch.update(docRef, bigInvoice.toJson());

    if (student != null) {
      for (var sub in student.studentPaidSubscriptions!) {
        if (sub.subscriptionId == updatedInvoice.subscriptionFeeID) {
          sub.paidAmount += differenceAmount;
          break;
        }
      }
      final studentRef = getSecondaryCollection(updatedInvoice.grade)
          .doc(updatedInvoice.studentId);
      batch.update(studentRef, student.toJson());
    }

    await batch.commit();
  }

  static Future<void> deleteInvoiceFromBigInvoices({
    required String date,
    required Invoice invoice,
  }) async {
    final docRef = _db.doc(teacherPath).collection('big_invoices').doc(date);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (!docSnapshot.exists) throw Exception("BigInvoice not found");

    final rawData = docSnapshot.data();
    if (rawData == null) throw Exception("BigInvoice data is null for $date");
    Map<String, dynamic> data = rawData as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    int index = bigInvoice.invoices.indexWhere((inv) => inv.id == invoice.id);
    if (index == -1) throw Exception("Invoice not found");

    bigInvoice.invoices.removeAt(index);

    Studentmodel? student = await FirebaseExams.getStudent(
      invoice.grade,
      invoice.studentId,
    );

    // Atomic batch: delete invoice AND update student paidAmount together
    final batch = _db.batch();
    batch.update(docRef, bigInvoice.toJson());

    if (student != null && student.studentPaidSubscriptions != null) {
      for (var sub in student.studentPaidSubscriptions!) {
        if (sub.subscriptionId == invoice.subscriptionFeeID) {
          sub.paidAmount -= invoice.amount;
          if (sub.paidAmount < 0) sub.paidAmount = 0;
          break;
        }
      }
      final studentRef =
          getSecondaryCollection(invoice.grade).doc(invoice.studentId);
      batch.update(studentRef, student.toJson());
    }

    await batch.commit();
  }

  static Future<List<Invoice>> getInvoicesByStudenId(String studentID) async {
    // التعديل: البحث في فواتير المدرس الحالي فقط
    QuerySnapshot snapshot =
        await _db.doc(teacherPath).collection('big_invoices').get();

    List<Invoice> studentInvoices = [];

    for (var doc in snapshot.docs) {
      final rawData = doc.data();
      if (rawData == null) continue;
      Map<String, dynamic> data = rawData as Map<String, dynamic>;
      DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

      var matchingInvoices = bigInvoice.invoices
          .where((invoice) => invoice.studentId == studentID)
          .toList();

      studentInvoices.addAll(matchingInvoices);
    }
    return studentInvoices;
  }

  //  ................===============     subscriptions   ==============........................
// =============================== Subscriptions (Sub-collections) ===============================

  static Future<void> createGradeSubscriptionDoc(
      GradeSubscriptionsModel model) async {
    // التعديل: الحفظ داخل constants المدرس
    await _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(model.gradeName)
        .set(model.toJson());
  }

  static Future<void> addSubscriptionToGrade(String gradeName,
      String subscriptionName, double subscriptionAmount) async {
    final docRef = _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();
    final tempId = _db.collection('temp_ids').doc().id;

    final newSubscription = SubscriptionFee(
      id: tempId,
      subscriptionName: subscriptionName.trim(),
      subscriptionAmount: subscriptionAmount,
    );

    if (!doc.exists) {
      final newGrade = GradeSubscriptionsModel(
        gradeName: gradeName,
        subscriptions: [newSubscription],
      );
      await docRef.set(newGrade.toJson());
      return;
    }

    final grade = GradeSubscriptionsModel.fromJson(doc.data()!);
    grade.subscriptions.add(newSubscription);

    await docRef.update({
      'subscriptions': grade.subscriptions.map((e) => e.toJson()).toList(),
    });
  }

  static Future<void> updateSubscriptionInGrade(
    String gradeName,
    SubscriptionFee updatedSubscription,
  ) async {
    final docRef = _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Grade '$gradeName' does not exist.");

    final grade = GradeSubscriptionsModel.fromJson(doc.data()!);
    final index =
        grade.subscriptions.indexWhere((s) => s.id == updatedSubscription.id);

    if (index == -1) throw Exception("Subscription not found.");

    grade.subscriptions[index] = updatedSubscription;

    await docRef.update({
      'subscriptions': grade.subscriptions.map((e) => e.toJson()).toList(),
    });
  }

  static Future<void> deleteSubscriptionFromGrade(
      String gradeName, String subscriptionId) async {
    final docRef = _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Grade '$gradeName' does not exist.");

    final grade = GradeSubscriptionsModel.fromJson(doc.data()!);
    grade.subscriptions.removeWhere((s) => s.id == subscriptionId);

    await docRef.update({
      'subscriptions': grade.subscriptions.map((e) => e.toJson()).toList(),
    });
  }

  static Future<SubscriptionFee?> getSubscriptionById(
      String gradeName, String subscriptionId) async {
    final docRef = _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc =
        await docRef.get(const GetOptions(source: Source.serverAndCache));

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['subscriptions'] == null) return null;

    final subscriptions = (data['subscriptions'] as List)
        .map((e) => SubscriptionFee.fromJson(e as Map<String, dynamic>))
        .toList();

    try {
      return subscriptions.firstWhere((sub) => sub.id == subscriptionId);
    } catch (e) {
      return null;
    }
  }

  static Stream<GradeSubscriptionsModel?> getGradeSubscriptionsStream(
      String gradeName) {
    return _db
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return GradeSubscriptionsModel.fromJson(snapshot.data()!);
    });
  }

  // =============================== Password Management ===============================

  /// Hash a password using SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> verifyPassword(String enteredPassword) async {
    try {
      final docRef =
          _db.doc(teacherPath).collection('constants').doc('password');
      final doc = await docRef.get();

      if (!doc.exists) {
        // First time — store hashed default
        await docRef.set({
          'password': _hashPassword('0'),
          'isHashed': true,
        });
        return enteredPassword == '0';
      }

      final data = doc.data()!;
      final savedPassword = data['password'] ?? '0';
      final isHashed = data['isHashed'] ?? false;

      if (!isHashed) {
        // Migrate plaintext → hashed on successful login
        if (enteredPassword == savedPassword) {
          await docRef.set({
            'password': _hashPassword(enteredPassword),
            'isHashed': true,
          });
          return true;
        }
        return false;
      }

      return _hashPassword(enteredPassword) == savedPassword;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> changePassword(String newPassword) async {
    try {
      await _db
          .doc(teacherPath)
          .collection('constants')
          .doc('password')
          .set({
        'password': _hashPassword(newPassword),
        'isHashed': true,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  // =============================== Absence Management ===============================

  static Future<void> deleteAbsenceFromSubcollection(
      String day, String magmo3aId, String absenceDate) async {
    try {
      // getDayCollection تجلب المسار الصحيح للمدرس تلقائياً
      DocumentReference magmo3aDocRef = getDayCollection(day).doc(magmo3aId);

      await magmo3aDocRef.collection('absences').doc(absenceDate).delete();
    } catch (e) {
      print("Error: $e");
    }
  }

  static Future<void> updateAbsenceByDateInSubcollection(
    String day,
    String magmo3aId,
    String absenceDate,
    AbsenceModel updatedAbsence,
  ) async {
    try {
      DocumentReference magmo3aDocRef = getDayCollection(day).doc(magmo3aId);

      await magmo3aDocRef
          .collection('absences')
          .doc(absenceDate)
          .set(updatedAbsence.toJson(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  static Stream<AbsenceModel?> getAbsenceByDateStream(
      String day, String groupId, String date) {
    // التعديل: استخدام getDayCollection للوصول لمسار المدرس
    return getDayCollection(day)
        .doc(groupId)
        .collection('absences')
        .doc(date)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return AbsenceModel.fromJson(docSnapshot.data()!);
      }
      return null;
    });
  }

  static Future<AbsenceModel?> getAbsenceByDateOnce(
      String day, String groupId, String date) async {
    final docSnapshot = await getDayCollection(day)
        .doc(groupId)
        .collection('absences') // تأكد من مطابقة المسار 'absence' أو 'absences'
        .doc(date)
        .get(const GetOptions(source: Source.server));

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return AbsenceModel.fromJson(docSnapshot.data()!);
    }
    return null;
  }

  // =============================== Helper Getters ===============================

  static Future<Studentmodel?> getStudentById(
      String grade, String studentId) async {
    final doc = await getSecondaryCollection(grade).doc(studentId).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<QuerySnapshot<Studentmodel>> getStudentsByGroupIdOnce(
      String grade, String groupId) async {
    // التعديل هنا بيضمن إن لو المدرس دخل المجموعة دي قبل كده، الداتا تظهر Offline
    return await getSecondaryCollection(grade)
        .where("hisGroupsId", arrayContains: groupId)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  static Future<Teacher?> getTeacherById(String id) async {
    // أضفنا GetOptions عشان يفتح البروفايل فوراً من الموبايل
    var doc = await _db
        .collection('teachers')
        .doc(id)
        .get(const GetOptions(source: Source.serverAndCache));

    return doc.exists ? Teacher.fromJson(doc.data()!, doc.id) : null;
  }

  /// Queue a referral reward for the host teacher (processed on their next login)
  /// Instead of writing directly to another teacher's doc (which security rules block),
  /// we write to a shared 'referral_rewards' collection.
  static Future<void> queueReferralReward({
    required String hostTeacherId,
    required String inviterName,
  }) async {
    await _db.collection('referral_rewards').add({
      'hostTeacherId': hostTeacherId,
      'inviterName': inviterName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Process any pending referral rewards for the current teacher.
  /// Called on login — the teacher processes their own rewards (writing to their own doc).
  static Future<void> processReferralRewards(String teacherId) async {
    try {
      final snapshot = await _db
          .collection('referral_rewards')
          .where('hostTeacherId', isEqualTo: teacherId)
          .get();

      if (snapshot.docs.isEmpty) return;

      // نجلب بيانات المدرس الحالية عشان نحسب الليمت بتاعه
      final teacherDoc = await _db.collection('teachers').doc(teacherId).get();
      int baseLimit = 30; // افتراضي

      if (teacherDoc.exists) {
        final teacher = Teacher.fromJson(
            teacherDoc.data() as Map<String, dynamic>, teacherId);
        baseLimit = await teacher.getBaseStudentLimit();
      }

      // الخدعة هنا: لو المدرس كان منتهي الصلاحية، الليمت هيطلع صفر
      // لو سيبناه صفر، هيدخل في فترة سماح إجبارية بمجرد ما يفتح، فنعطيه 30 كحد أدنى
      if (baseLimit <= 0) {
        baseLimit = 30;
      }

      for (var rewardDoc in snapshot.docs) {
        final data = rewardDoc.data();
        final inviterName = data['inviterName'] ?? 'مدرس';

        try {
          // مسح المكافأة من قاعدة البيانات "أولاً" لمنع تكرارها لو حصل Refresh سريع
          await rewardDoc.reference.delete();

          // ثم تطبيق المكافأة بأمان
          await renewBasicSubscription(
            plan: Subscription(
              name: "مكافأة دعوة صديق",
              description: "أسبوع مجاني لاستضافة المدرس ($inviterName)",
              durationInDays: 7,
              price: 0,
              subscriptionType: SubscriptionType.adminSubscription,
              totalStudents: baseLimit,
            ),
            paymentRef: "Referral bonus for inviting $inviterName",
            teacherId: teacherId,
          );
        } catch (e) {
          debugPrint("Failed to process referral reward: $e");
        }
      }
    } catch (e) {
      debugPrint("Error checking referral rewards: $e");
    }
  }

  static Future<void> runAttendanceTransaction({
    required Studentmodel student,
    required AbsenceModel currentGroupAbsence,
    required String currentDay,
    required String currentMagmo3aId,
    required String currentDate,
    // اختياري: للمجموعة الأصلية لو الطالب تعويض
    AbsenceModel? otherGroupAbsence,
    SecondaryRecord? otherGroupInfo,
  }) async {
    final batch = _db.batch();
    final rootPath = teacherPath; // استخدام المتغير الموجود عندك

    // 1. مرجع وثيقة الطالب
    final studentRef = _db
        .doc('$rootPath/${student.grade}/${student.id}'); // اختصار رهيب للمسار

    batch.update(studentRef, student.toJson());

    // 2. مرجع وثيقة الحضور للمجموعة الحالية
    final currentAbsenceRef = _db
        .doc('$rootPath/$currentDay/$currentMagmo3aId/absences/$currentDate');

    batch.set(currentAbsenceRef, currentGroupAbsence.toJson(),
        SetOptions(merge: true));

    // 3. مرجع وثيقة الحضور للمجموعة الأخرى (إن وجدت)
    if (otherGroupAbsence != null && otherGroupInfo != null) {
      final otherAbsenceRef = _db.doc(
          '$rootPath/${otherGroupInfo.day}/${otherGroupInfo.magmo3aId}/absences/${otherGroupInfo.date}');

      batch.set(
          otherAbsenceRef, otherGroupAbsence.toJson(), SetOptions(merge: true));
    }

    // تنفيذ الباتش
    await batch.commit();
  }

  // تجديد الاشتراك الأساسي (Basic)
  static Future<void> renewBasicSubscription({
    required Subscription plan,
    String? manualBillId,
    required String? paymentRef,
    String? teacherId,
  }) async {
    try {
      final String targetTeacherId =
          teacherId ?? FirebaseAuth.instance.currentUser!.uid;

      final String path = "teachers/$targetTeacherId";
      final now = DateTime.now();

      // جلب بيانات المدرس الحالية
      DocumentSnapshot teacherDoc = await _db.doc(path).get();

      // تصحيح: لو المدرس لسه جديد (في حالة الـ Register)، مش هينفع نقرأ منه تاريخ قديم
      DateTime currentExpiry;
      if (teacherDoc.exists && teacherDoc.data() != null) {
        Map<String, dynamic> tData = teacherDoc.data() as Map<String, dynamic>;
        currentExpiry = DateTime.parse(
            tData['subscriptionEndTime'] ?? now.toIso8601String());
      } else {
        currentExpiry = now;
      }

      // الحسبة بتاعتك زي ما هي
      DateTime baseDate = currentExpiry.isAfter(now) ? currentExpiry : now;
      DateTime newExpiryDate =
          baseDate.add(Duration(days: plan.durationInDays));

      WriteBatch batch = _db.batch();
      DocumentReference teacherRef = _db.doc(path);

      // تصحيح الـ ID: لو manualBillId موجود نستخدمه، لو null نخلي Firestore يولد ID جديد تلقائي
      DocumentReference billRef = manualBillId != null
          ? teacherRef.collection('bills').doc(manualBillId)
          : teacherRef.collection('bills').doc();

      // 1. تحديث بيانات المدرس (استخدام set مع merge أضمن أمنياً من update في حالات الـ Register)
      batch.set(
          teacherRef,
          {
            'subscriptionEndTime': newExpiryDate.toIso8601String(),
        'isActive': true,
            'gracePeriodEndTime': null,
          },
          SetOptions(merge: true));

      // 2. إنشاء الفاتورة
      Bill newBill = Bill(
        id: billRef.id,
        paymentRef: paymentRef,
        billType: plan.subscriptionType.name,
        baseStudentLimit: plan.totalStudents,
        subscriptionName: plan.name,
        subscriptionDurationInDays: plan.durationInDays,
        billAmount: plan.price,
        paidAt: now,
        expiryDate: newExpiryDate,
        subscriptionDescription: plan.description,
        subscriptionId: plan.id ?? "",
        teacherId: targetTeacherId,
      );

      batch.set(billRef, newBill.toJson());
      await batch.commit();
    } on Exception catch (e) {
      if (e.toString().contains("AUTH_REQUIRED")) {
        rethrow;
      }
      throw Exception("فشل التجديد: $e");
    }
  }

  // إضافة بوست (Boost)
  static Future<void> renewBoostSubscription(
      {required Subscription boostPlan,
      String? manualBillId,
      required String? paymentRef}) async {
    try {
      final String path = teacherPath;
      final now = DateTime.now();
      DateTime boostExpiry = now.add(Duration(days: boostPlan.durationInDays));

      WriteBatch batch = _db.batch();
      DocumentReference teacherRef = _db.doc(path);
      DocumentReference billRef =
          teacherRef.collection('bills').doc(manualBillId);

      ActiveBoost newBoost = ActiveBoost(
        id: billRef.id,
        studentAmount: boostPlan.totalStudents,
        expiryDate: boostExpiry,
        purchasedAt: now,
      );

      batch.update(teacherRef, {
        'activeBoosts': FieldValue.arrayUnion([newBoost.toJson()]),
      });

      Bill newBill = Bill(
        id: billRef.id,
        subscriptionId: boostPlan.id ?? '',
        paymentRef: paymentRef,
        teacherId: FirebaseAuth.instance.currentUser!.uid,
        billAmount: boostPlan.price,
        paidAt: now,
        expiryDate: boostExpiry,
        subscriptionName: boostPlan.name,
        subscriptionDescription: boostPlan.description,
        subscriptionDurationInDays: boostPlan.durationInDays,
        billType: boostPlan.subscriptionType.name,
        boostAmount: boostPlan.totalStudents,
      );

      batch.set(billRef, newBill.toJson());
      await batch.commit();
    } on Exception catch (e) {
      if (e.toString().contains("AUTH_REQUIRED")) rethrow;
      throw Exception("فشل إضافة البوست: $e");
    }
  }

  // Cached subscription plans — fetched once and reused.
  // These rarely change (admin manages them) so real-time listeners are wasteful.
  // Each listener at 1000+ teachers = 1000+ concurrent connections to global collection.
  static List<Subscription>? _cachedBoostSubs;
  static List<Subscription>? _cachedOffersSubs;
  static List<Subscription>? _cachedSubs;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 30);

  static bool _cacheValid() {
    return _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl;
  }

  /// Clear the subscription cache (e.g. on logout)
  static void clearSubscriptionCache() {
    _cachedBoostSubs = null;
    _cachedOffersSubs = null;
    _cachedSubs = null;
    _cacheTime = null;
  }

  /// One-time fetch (cached for 30 min). Use this instead of a live stream
  /// because subscription plans rarely change.
  static Future<List<Subscription>> fetchBoostSubscriptions(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBoostSubs != null && _cacheValid()) {
      return _cachedBoostSubs!;
    }
    final snap = await _db.collection('admin_boost_subscriptions').get();
    _cachedBoostSubs = snap.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
    _cacheTime = DateTime.now();
    return _cachedBoostSubs!;
  }

  static Future<List<Subscription>> fetchOffersSubscriptions(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedOffersSubs != null && _cacheValid()) {
      return _cachedOffersSubs!;
    }
    final snap = await _db.collection('admin_offers_subscriptions').get();
    _cachedOffersSubs = snap.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
    _cacheTime = DateTime.now();
    return _cachedOffersSubs!;
  }

  static Future<List<Subscription>> fetchSubscriptions(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSubs != null && _cacheValid()) {
      return _cachedSubs!;
    }
    final snap = await _db.collection('admin_subscriptions').get();
    _cachedSubs = snap.docs
        .map((doc) => Subscription.fromJson(doc.data(), doc.id))
        .toList();
    _cacheTime = DateTime.now();
    return _cachedSubs!;
  }

  // Backwards-compat: keep the stream API but use cached fetch (single emit).
  // Existing StreamBuilder UIs keep working without changes.
  static Stream<List<Subscription>> getBoostSubscriptions() async* {
    yield await fetchBoostSubscriptions();
  }

  static Stream<List<Subscription>> getOffersSubscriptions() async* {
    yield await fetchOffersSubscriptions();
  }

  static Stream<List<Subscription>> getSubscriptions() async* {
    yield await fetchSubscriptions();
  }

// في ملف FirebaseFunctions
  static Future<void> checkAndResolvePendingPayment(
      String teacherId, BuildContext context) async {
    try {
      // 1. هات كل العمليات المعلقة الخاصة بالمدرس ده
      final querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('pending_payments')
          .get();

      if (querySnapshot.docs.isEmpty) return; // مفيش حاجة، اطلع

      // 2. لوب على العمليات (ممكن يكون حاول كذا مرة)
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final String? ref = data['ref'] as String?;
          final String? billId = data['billId'] as String?;
          final planMap = data['plan'] as Map<String, dynamic>?;

          // Skip malformed entries
          if (ref == null || billId == null || planMap == null) {
            debugPrint("Skipping malformed pending payment: ${doc.id}");
            continue;
          }

          final Subscription plan =
              Subscription.fromJson(planMap, planMap['id'] ?? '');

          debugPrint("Checking cloud pending payment: $ref");

          // 3. اسأل EasyKash
          final statusData = await EasyKashService.checkPaymentStatus(ref);

          if (statusData != null &&
              (statusData['status'] == "PAID" ||
                  statusData['status'] == "SUCCESS")) {
            // --- نجاح: فعل الاشتراك ---
            bool isBoost =
                plan.subscriptionType.toString().toLowerCase().contains('boost');

            if (isBoost) {
              await renewBoostSubscription(
                  boostPlan: plan, manualBillId: billId, paymentRef: ref);
            } else {
              await renewBasicSubscription(
                  plan: plan, manualBillId: billId, paymentRef: ref);
            }

            // تحديث الـ UI لو السياق موجود
            if (context.mounted) {
              await Provider.of<TeacherProvider>(context, listen: false)
                  .refreshTeacherData();

              AppSnackBars.showSuccess(
                context,
                "تم استعادة عملية دفع سابقة وتفعيل الاشتراك بنجاح!",
              );
            }

            // حذف العملية المعلقة بعد النجاح
            await doc.reference.delete();
          } else if (statusData != null &&
              (statusData['status'] == "FAILED" ||
                  statusData['status'] == "EXPIRED")) {
            // --- فشل نهائي: احذفها عشان منظلش نسأل عليها ---
            await doc.reference.delete();
            if (context.mounted) {
              AppSnackBars.showError(
                context,
                "نعتذر ولكن لم تتم العمليه السابقه بنجاح !",
              );
            }
          }
          // لو لسه PENDING سيبها، يمكن يدفع كمان شويه
        } catch (e) {
          debugPrint("Error processing pending payment ${doc.id}: $e");
          // Continue to next payment instead of stopping the whole loop
        }
      }
    } catch (e) {
      debugPrint("Error in cloud payment check: $e");
    }
  }
}
