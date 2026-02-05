import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_management_system/models/absence_app/absence_model.dart';
import 'package:student_management_system/models/absence_app/secondary_record.dart';
import 'package:student_management_system/models/admin/teacher.dart';

import '../models/Invoice.dart';
import '../models/Magmo3aModel.dart';
import '../models/Student_model.dart';
import '../models/absence_app/student_absence_model.dart';
import '../models/daily_invoice.dart';
import '../models/grade_subscriptions_model.dart';
import '../models/payment.dart';
import '../models/subscription_fee.dart';
import 'exams_functions.dart';

class FirebaseFunctions {
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
  static Future<void> editMagmo3aInDay(String oldDay,
      String oldGrade,
      Magmo3amodel updatedMagmo3a,) async {
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
    final firestore = FirebaseFirestore.instance;

    try {
      // 1️⃣ حذف الـ Sub-collection (absences) أولاً
      final absenceCollection =
          getDayCollection(day).doc(magmo3aId).collection('absences');

      final absenceSnapshot = await absenceCollection.get();

      if (absenceSnapshot.docs.isNotEmpty) {
        final batch = firestore.batch();
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

      final studentBatch = firestore.batch();
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
    return FirebaseFirestore.instance
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
    final firestore = FirebaseFirestore.instance;

    try {
      final grades = await FirebaseFunctions.getGradesList();

      await Future.wait(grades.map((grade) async {
        final collection = getSecondaryCollection(grade);
        final snapshot = await collection.get();

        if (snapshot.docs.isEmpty) return;

        final studentDocs = snapshot.docs;
        const batchLimit = 500;

        for (var i = 0; i < studentDocs.length; i += batchLimit) {
          final batch = firestore.batch();
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
    final firestore = FirebaseFirestore.instance;

    try {
      if (deleteInvoices) {
        final invoicesSnap =
            await firestore.doc(teacherPath).collection('big_invoices').get();

        final invoiceBatch = firestore.batch();
        for (var doc in invoicesSnap.docs) {
          invoiceBatch.delete(doc.reference);
        }
        await invoiceBatch.commit();

        // نغير القيمة لـ false عشان ميتكررش الحذف مع كل مرحلة لو مختار أكتر من مرحلة
        deleteInvoices = false;
      }

      // 1. مسح اشتراكات المرحلة - المسار الجديد داخل ثابت المدرس
      if (resetSubscriptions && gradeName.isNotEmpty) {
        await firestore
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
          final batch = firestore.batch();
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
          await firestore
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

            final groupBatch = firestore.batch();
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
    DocumentReference teacherDoc = FirebaseFirestore.instance.doc(teacherPath);

    // بنستخدم Batch عشان نضمن إن الطالب يتضاف والعداد يزيد مع بعض (أو لا قدر الله لو فشل واحد التاني ميتعملش)
    WriteBatch batch = FirebaseFirestore.instance.batch();

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
    DocumentReference teacherDoc = FirebaseFirestore.instance.doc(teacherPath);

    WriteBatch batch = FirebaseFirestore.instance.batch();

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
    final firestore = FirebaseFirestore.instance;

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

    WriteBatch batch = firestore.batch();

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
    return FirebaseFirestore.instance
        .doc(teacherPath)
        .collection(grade)
        .withConverter<Studentmodel>(
          fromFirestore: (snapshot, _) =>
              Studentmodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        );
  }
  static Future<void> addGradeToList(String newGrade) async {
    try {
      // تعديل المسار: الثوابت بقت خاصة بكل مدرس
      final gradesDoc = FirebaseFirestore.instance
          .doc(teacherPath)
          .collection('constants')
          .doc('grades');

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
      DocumentReference gradesDoc = FirebaseFirestore.instance
          .doc(teacherPath)
          .collection('constants')
          .doc('grades');

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
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
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
      final fireStore = FirebaseFirestore.instance;
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
    return FirebaseFirestore.instance
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
        FirebaseFirestore.instance.doc(teacherPath).collection('big_invoices');

    await bigInvoicesCollection.doc('dummy').set({'dummyField': 'dummyValue'});
  }

  static Future<void> deleteBigInvoiceCollection() async {
    // التعديل: الوصول للكولكشن الخاص بالمدرس
    CollectionReference bigInvoicesCollection =
        FirebaseFirestore.instance.doc(teacherPath).collection('big_invoices');

    QuerySnapshot snapshot = await bigInvoicesCollection.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Stream<QuerySnapshot> getAllBigInvoices() {
    // التعديل: استماع للفواتير الخاصة بالمدرس الحالي فقط
    return FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .snapshots();
  }

  static Future<void> updateDailyInvoice(
      String date, DailyInvoice bigInvoice) async {
    CollectionReference invoicesCollection =
        FirebaseFirestore.instance.doc(teacherPath).collection('big_invoices');

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
    final docRef = FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .doc(date);

    final docSnapshot = await docRef.get();

    final newPayment = Payment(
      amount: double.tryParse(amountText) ?? 0.0,
      description: description.trim(),
      dateTime: DateTime.now(),
    );

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
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
        FirebaseFirestore.instance.doc(teacherPath).collection('big_invoices');

    DocumentSnapshot docSnapshot = await invoicesCollection.doc(date).get();

    if (!docSnapshot.exists) {
      throw Exception("Document with date $date does not exist");
    }

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    if (paymentIndex < 0 || paymentIndex >= bigInvoice.payments.length) {
      throw Exception("Invalid payment index");
    }
    bigInvoice.payments[paymentIndex] = updatedPayment;

    await invoicesCollection.doc(date).set(bigInvoice.toJson());
  }

  // ✅ تعديل جلب الـ ID التسلسلي ليكون خاص بكل مدرس
  static Future<int> getAndIncrementInvoiceId() async {
    // العداد أصبح داخل constants المدرس
    DocumentReference docRef = FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('constants')
        .doc('bills_ids');

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {'bills_ids': 1});
        return 1;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      int currentId = (data?['bills_ids'] ?? 0) + 1;

      transaction.update(docRef, {'bills_ids': currentId});
      return currentId;
    });
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
    DocumentReference docRef = FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .doc(date);

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
    // التعديل: المسار تحت المدرس
    final docRef = FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .doc(date);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception("BigInvoice for $date not found");
    }

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    int index = bigInvoice.invoices
        .indexWhere((invoice) => invoice.id == updatedInvoice.id);

    if (index == -1) throw Exception("Invoice not found");

    bigInvoice.invoices[index] = updatedInvoice;
    await docRef.update(bigInvoice.toJson());

    // تحديث الطالب (getSecondaryCollection متعدلة بالفعل لتتبع المدرس)
    Studentmodel? student = await FirebaseExams.getStudent(
      updatedInvoice.grade,
      updatedInvoice.studentId,
    );

    if (student != null) {
      for (var sub in student.studentPaidSubscriptions!) {
        if (sub.subscriptionId == updatedInvoice.subscriptionFeeID) {
          sub.paidAmount += differenceAmount;
          break;
        }
      }
      await getSecondaryCollection(updatedInvoice.grade)
          .doc(updatedInvoice.studentId)
          .update(student.toJson());
    }
  }

  static Future<void> deleteInvoiceFromBigInvoices({
    required String date,
    required Invoice invoice,
  }) async {
    final docRef = FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .doc(date);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (!docSnapshot.exists) throw Exception("BigInvoice not found");

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    int index = bigInvoice.invoices.indexWhere((inv) => inv.id == invoice.id);
    if (index == -1) throw Exception("Invoice not found");

    bigInvoice.invoices.removeAt(index);
    await docRef.update(bigInvoice.toJson());

    Studentmodel? student = await FirebaseExams.getStudent(
      invoice.grade,
      invoice.studentId,
    );

    if (student != null && student.studentPaidSubscriptions != null) {
      for (var sub in student.studentPaidSubscriptions!) {
        if (sub.subscriptionId == invoice.subscriptionFeeID) {
          sub.paidAmount -= invoice.amount;
          if (sub.paidAmount < 0) sub.paidAmount = 0;
          break;
        }
      }
      await getSecondaryCollection(invoice.grade)
          .doc(invoice.studentId)
          .update(student.toJson());
    }
  }

  static Future<List<Invoice>> getInvoicesByStudenId(String studentID) async {
    // التعديل: البحث في فواتير المدرس الحالي فقط
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('big_invoices')
        .get();

    List<Invoice> studentInvoices = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
    await FirebaseFirestore.instance
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(model.gradeName)
        .set(model.toJson());
  }

  static Future<void> addSubscriptionToGrade(String gradeName,
      String subscriptionName, double subscriptionAmount) async {
    final firestore = FirebaseFirestore.instance;

    final docRef = firestore
        .doc(teacherPath)
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();
    final tempId = firestore.collection('temp_ids').doc().id;

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
    final docRef = FirebaseFirestore.instance
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
    final docRef = FirebaseFirestore.instance
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
    final docRef = FirebaseFirestore.instance
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
    return FirebaseFirestore.instance
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

  static Future<bool> verifyPassword(String enteredPassword) async {
    try {
      // كلمة المرور أصبحت داخل doc خاص بكل مدرس
      final docRef = FirebaseFirestore.instance
          .doc(teacherPath)
          .collection('constants')
          .doc('password');
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({'password': '0'});
        return enteredPassword == '0';
      }

      final savedPassword = doc.data()?['password'] ?? '0';
      return enteredPassword == savedPassword;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> changePassword(String newPassword) async {
    try {
      await FirebaseFirestore.instance
          .doc(teacherPath)
          .collection('constants')
          .doc('password')
          .set({'password': newPassword}, SetOptions(merge: true));
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
    var doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(id)
        .get(const GetOptions(source: Source.serverAndCache));

    return doc.exists ? Teacher.fromJson(doc.data()!, doc.id) : null;
  }

  // داخل FirebaseFunctions

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
    final batch = FirebaseFirestore.instance.batch();
    final rootPath = teacherPath; // استخدام المتغير الموجود عندك

    // 1. مرجع وثيقة الطالب
    final studentRef = FirebaseFirestore.instance
        .doc('$rootPath/${student.grade}/${student.id}'); // اختصار رهيب للمسار

    batch.update(studentRef, student.toJson());

    // 2. مرجع وثيقة الحضور للمجموعة الحالية
    final currentAbsenceRef = FirebaseFirestore.instance
        .doc('$rootPath/$currentDay/$currentMagmo3aId/absences/$currentDate');

    batch.set(currentAbsenceRef, currentGroupAbsence.toJson(),
        SetOptions(merge: true));

    // 3. مرجع وثيقة الحضور للمجموعة الأخرى (إن وجدت)
    if (otherGroupAbsence != null && otherGroupInfo != null) {
      final otherAbsenceRef = FirebaseFirestore.instance.doc(
          '$rootPath/${otherGroupInfo.day}/${otherGroupInfo.magmo3aId}/absences/${otherGroupInfo.date}');

      batch.set(
          otherAbsenceRef, otherGroupAbsence.toJson(), SetOptions(merge: true));
    }

    // تنفيذ الباتش
    await batch.commit();
  }
}
