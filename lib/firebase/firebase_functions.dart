import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_management_system/models/absence_app/absence_model.dart';

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

    // 🧩 1️⃣ Move document if the day changed
    if (newDay != oldDay) {
      final oldDayCollection = getDayCollection(oldDay);
      await oldDayCollection.doc(updatedMagmo3a.id).delete();

      final newDayCollection = getDayCollection(newDay!);
      await newDayCollection.doc(updatedMagmo3a.id).set(updatedMagmo3a);
    } else {
      final dayCollection = getDayCollection(newDay!);
      await dayCollection.doc(updatedMagmo3a.id).set(updatedMagmo3a);
    }

    // 🧩 2️⃣ Fetch all students who have this group (from OLD grade)
    final studentsSnapshot = await getStudentsByGroupId(
      oldGrade, // you can replace with oldGrade if needed
      updatedMagmo3a.id,
    ).first;

    // 🧩 3️⃣ Update their hisGroups
    for (var doc in studentsSnapshot.docs) {
      final data = doc.data();

      // Make sure to handle both converter or raw JSON cases
      final student = data;

      bool updated = false;

      if (student.hisGroups != null) {
        for (int i = 0; i < student.hisGroups!.length; i++) {
          if (student.hisGroups![i].id == updatedMagmo3a.id) {
            student.hisGroups![i] = updatedMagmo3a;
            updated = true;
          }
        }
      }

      if (updated) {
        await getSecondaryCollection(oldGrade).doc(student.id).update({
          "hisGroups": student.hisGroups!.map((g) => g.toJson()).toList(),
        });
      }
    }
  }

  /// Deletes a `Magmo3aModel` document from a specific day's collection
  static Future<void> deleteMagmo3aFromDay({
    required String day,
    required String grade,
    required String magmo3aId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1️⃣ حذف الـ Sub-collection (absences) أولاً
      // في فايربيز، لازم تمسح المستندات اللي جوه الـ sub-collection قبل ما تمسح الـ parent doc
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

      // 3️⃣ تنظيف بيانات الطلاب (Removing the group from students)
      // بنجيب كل طلاب المرحلة دي
      List<Studentmodel> allStudents =
          await getAllStudentsByGrade_future(grade);

      final studentBatch = firestore.batch();
      bool needsUpdate = false;

      for (var student in allStudents) {
        bool studentChanged = false;

        // حذف من list الـ IDs
        if (student.hisGroupsId != null &&
            student.hisGroupsId!.contains(magmo3aId)) {
          student.hisGroupsId!.remove(magmo3aId);
          studentChanged = true;
        }

        // حذف من list الـ Objects
        if (student.hisGroups != null) {
          int initialLength = student.hisGroups!.length;
          student.hisGroups!.removeWhere((group) => group.id == magmo3aId);
          if (student.hisGroups!.length != initialLength) {
            studentChanged = true;
          }
        }

        // لو الطالب كان مشترك في المجموعة دي، بنحدث بياناته في الباتش
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

  /// Retrieves all documents in a specific day's collection for the current user
  static Stream<List<Magmo3amodel>> getAllDocsFromDay(String day) {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);
    return dayCollection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves all documents in a specific day's collection filtered by grade
  static Stream<List<Magmo3amodel>> getAllDocsFromDayWithGrade(
      String day, String grade) {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);

    return dayCollection
        .where("grade", isEqualTo: grade)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Deletes all absence records in the "absences" subcollection under each `Magmo3a` document
  static Future<void> deleteAbsencesSubCollection(String day) async {
    try {
      CollectionReference dayCollection =
          FirebaseFirestore.instance.collection(day);
      QuerySnapshot daySnapshot = await dayCollection.get();

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

  /// Returns a reference to the specific day's collection
  static CollectionReference<Magmo3amodel> getDayCollection(String day) {
    return FirebaseFirestore.instance
        .collection(day)
        .withConverter<Magmo3amodel>(
          fromFirestore: (snapshot, _) =>
              Magmo3amodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        );
  }

  // =============================== Student Functions ===============================

  /// Adds a `StudentModel` to a specific grade's collection
  static Future<String> addStudentToCollection(
      String grade, Studentmodel studentModel) async {
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);

    DocumentReference<Studentmodel> newDocRef = collection.doc();
    studentModel.id = newDocRef.id;
    await newDocRef.set(studentModel);
    return newDocRef.id;
  }

  static Future<void> saveMonthAndStartNew(String monthName) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final grades = await FirebaseFunctions.getGradesList();

      // Process all grades in parallel for speed
      await Future.wait(grades.map((grade) async {
        final collection = getSecondaryCollection(grade);

        // OPTIONAL: Add .where('lastProcessedMonth', isNotEqualTo: monthName)
        // to make the function resumable if it crashes.
        final snapshot = await collection.get();

        if (snapshot.docs.isEmpty) return;

        final studentDocs = snapshot.docs;
        const batchLimit = 500; // Firestore maximum batch size

        for (var i = 0; i < studentDocs.length; i += batchLimit) {
          final batch = firestore.batch();
          final chunk = studentDocs.skip(i).take(batchLimit);

          for (final doc in chunk) {
            final student = doc.data();

            // Construct the new history object
            final newAbsence = StudentAbsencesModel(
              monthName: monthName,
              attendedDays: student.countingAttendedDays ?? [],
              absentDays: student.countingAbsentDays ?? [],
            ).toJson();

            batch.update(doc.reference, {
              // 1. arrayUnion prevents duplicate objects if the script runs twice
              'absencesNumbers': FieldValue.arrayUnion([newAbsence]),
              // 2. Reset the counters
              'countingAttendedDays': [],
              'countingAbsentDays': [],
            });
          }

          await batch.commit();
        }
        print("✅ Completed Grade: $grade");
      }));

      print("🎉 All students across all grades updated successfully.");
    } catch (e) {
      print("❌ Critical Error: $e");
      rethrow;
    }
  }

// --- Firebase Functions ---

  static Future<void> resetGradeData({
    required String gradeName,
    required List<String> daysList, // أضفنا قائمة الأيام هنا
    required bool resetSubscriptions,
    required bool resetAbsence,
    required bool deleteExams,
    required bool deleteGroups,
    required bool deleteStudents,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. مسح اشتراكات المرحلة (Grade Level)
      if (resetSubscriptions) {
        await firestore
            .collection('constants')
            .doc('grades_subscriptions')
            .collection('grades')
            .doc(gradeName)
            .update({'subscriptions': []});
      }

      // 2. معالجة الطلاب (نفس المنطق السابق مع إضافة شرط الحذف النهائي)
      final allStudents = await getAllStudentsByGrade_future(gradeName);
      const batchSize = 400;

      for (int i = 0; i < allStudents.length; i += batchSize) {
        final batch = firestore.batch();
        final chunk = allStudents.skip(i).take(batchSize);

        for (final student in chunk) {
          final studentRef = getSecondaryCollection(gradeName).doc(student.id);

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

      // 3. حذف الامتحانات
      if (deleteExams) {
        await firestore.collection('exams').doc(gradeName).delete();
      }

      for (String day in daysList) {
        if (deleteGroups) {
          final groupSnap = await firestore
              .collection(day)
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
    } catch (e) {
      print("Error during reset: $e");
      rethrow;
    }
  }

  /// Deletes a `StudentModel` from a specific grade's collection
  static Future<void> deleteStudentFromHisCollection(
      String grade, String documentId) async {
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);
    await collection.doc(documentId).delete();
  }

  /// Updates a `StudentModel` document in a specific grade's collection
  static Future<void> updateStudentInCollection(
      String grade, String studentId, Studentmodel updatedStudentModel) async {
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);
    await collection.doc(studentId).update(updatedStudentModel.toJson());
  }

  /// Retrieves all students for a specific grade as a stream
  static Stream<List<Studentmodel>> getAllStudentsByGrade(String grade) {
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);
    return collection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Future<List<Studentmodel>> getAllStudentsByGrade_future(
      String grade) async {
    CollectionReference<Studentmodel> collection =
        getSecondaryCollection(grade);
    QuerySnapshot<Studentmodel> snapshot = await collection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Retrieves students filtered by first day ID
  static Stream<QuerySnapshot<Studentmodel>> getStudentsByGroupId(String grade,
      String groupId // The group ID you want to check in the `hisGroups` list
      ) {
    var collection =
        getSecondaryCollection(grade); // Get the collection based on grade

    return collection
        .where("hisGroupsId",
            arrayContains:
                groupId) // Check if the hisGroups array contains the groupId
        .snapshots();
  }

  /// Returns a reference to the specific grade's collection
  static CollectionReference<Studentmodel> getSecondaryCollection(
      String grade) {
    return FirebaseFirestore.instance
        .collection(grade)
        .withConverter<Studentmodel>(
          fromFirestore: (snapshot, _) =>
              Studentmodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        );
  }

  static Future<void> addGradeToList(String newGrade) async {
    try {
      // Reference to the 'constants' collection and the 'grades' document
      final gradesDoc =
          FirebaseFirestore.instance.collection('constants').doc('grades');

      // Get the current document data
      final snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        // ✅ If document exists, update the existing list
        final data = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> gradesList = List.from(data['grades'] ?? []);
        if (!gradesList.contains(newGrade)) {
          gradesList.add(newGrade);
        }

        await gradesDoc.update({'grades': gradesList});
        print("Grade added successfully (updated existing document).");
      } else {
        // ✅ If document doesn’t exist, create it with the new grade
        await gradesDoc.set({
          'grades': [newGrade],
        });
        print("Document created and grade added successfully.");
      }
    } catch (e) {
      print("Error adding grade: $e");
    }
  }

  static Future<void> deleteGradeFromList(String grade) async {
    try {
      // Reference to the 'constants' collection and the 'grades' document
      DocumentReference gradesDoc =
          FirebaseFirestore.instance.collection('constants').doc('grades');

      // Get the current document data
      DocumentSnapshot snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        // Get the current list of grades
        List<dynamic> gradesList = snapshot['grades'];

        // Remove the grade from the list
        gradesList.remove(grade);

        // Update the 'grades' field in the document with the modified list
        await gradesDoc.update({'grades': gradesList});

        print("Grade removed successfully.");
      } else {
        print("Document does not exist.");
      }
    } catch (e) {
      print("Error deleting grade: $e");
    }
  }

  static Future<List<String>> getGradesList() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('constants')
              .doc('grades')
              .get();

      if (docSnapshot.exists) {
        List<dynamic> gradesDynamic = docSnapshot.data()?['grades'] ?? [];
        List<String> grades =
            gradesDynamic.map((grade) => grade.toString()).toList();
        return grades;
      } else {
        print("Document does not exist.");
        return [];
      }
    } catch (e) {
      print("Error fetching grades: $e");
      return [];
    }
  }

  static Future<void> renameGrade(String oldGrade, String newGrade) async {
    try {
      final fireStore = FirebaseFirestore.instance;

      // 1️⃣ Update grade name in constants/grades list
      final DocumentReference gradesDoc =
          fireStore.collection('constants').doc('grades');
      final gradesSnapshot = await gradesDoc.get();

      if (gradesSnapshot.exists) {
        List<dynamic> gradesList = List.from(gradesSnapshot['grades']);
        if (gradesList.contains(oldGrade)) {
          int index = gradesList.indexOf(oldGrade);
          gradesList[index] = newGrade;
          await gradesDoc.update({'grades': gradesList});
        }
      }

      // 2️⃣ Move Students (Safe Batching for 500+ students)
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
          // If we hit 450 operations, commit and start a new batch
          if (count >= 450) {
            await studentBatch.commit();
            studentBatch = fireStore.batch();
            count = 0;
          }
        }
        if (count > 0) await studentBatch.commit();
        print('✅ Students moved safely.');
      }

      // 3️⃣ Update Magmo3a documents (Parallel Processing)
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
      print('✅ All magmo3a groups updated.');

      // 4️⃣ Rename Grade Subscription & Exams
      final batchFinal = fireStore.batch();

      final oldSubRef = fireStore
          .collection('constants')
          .doc('grades_subscriptions')
          .collection('grades')
          .doc(oldGrade);
      final newSubRef = fireStore
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

      final oldExamRef = fireStore.collection('exams').doc(oldGrade);
      final newExamRef = fireStore.collection('exams').doc(newGrade);
      final examSnap = await oldExamRef.get();

      if (examSnap.exists) {
        final examData = Map<String, dynamic>.from(examSnap.data()!);
        examData['gradeName'] = newGrade;
        batchFinal.set(newExamRef, examData);
        batchFinal.delete(oldExamRef);
      }
      await batchFinal.commit();

      // 5️⃣ Update Grade in "big_invoices" collection (Safe Batching)
      final bigInvoicesCollection = fireStore.collection('big_invoices');
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

        if (invCount > 0) {
          await invoiceBatch.commit();
          print('✅ Big Invoices updated.');
        }
      }
      print('🎉 Grade rename complete!');
    } catch (e, stack) {
      print('❌ Error: $e');
      print(stack);
    }
  }

  static Stream<List<String>> getGradesStream() {
    return FirebaseFirestore.instance
        .collection('constants')
        .doc('grades')
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists) {
        List<dynamic> gradesDynamic = docSnapshot.data()?['grades'] ?? [];
        return gradesDynamic.map((grade) => grade.toString()).toList();
      } else {
        return [];
      }
    });
  }

  //=============================== BigInvoices Functions ===============================
  static Future<void> createBigInvoiceCollection() async {
    // Get Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Reference to the collection (this will create the collection if it doesn't exist)
    CollectionReference bigInvoicesCollection =
        firestore.collection('big_invoices');

    // Optionally, you can add a dummy document to ensure the collection exists
    await bigInvoicesCollection.doc('dummy').set({'dummyField': 'dummyValue'});
  }

  static Future<void> deleteBigInvoiceCollection() async {
    // Get Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Reference to the collection
    CollectionReference bigInvoicesCollection =
        firestore.collection('big_invoices');

    // Get all documents in the collection
    QuerySnapshot snapshot = await bigInvoicesCollection.get();

    // Loop through each document and delete it
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Stream<QuerySnapshot> getAllBigInvoices() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    return firestore.collection('big_invoices').snapshots();
  }

  static Future<void> updateDailyInvoice(
      String date, DailyInvoice bigInvoice) async {
    // Reference to the Firestore collection
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference invoicesCollection =
        firestore.collection('big_invoices');

    // Check if the document exists
    DocumentSnapshot docSnapshot = await invoicesCollection.doc(date).get();

    if (docSnapshot.exists) {
      // If document exists, update it with the new data
      await invoicesCollection.doc(date).update(bigInvoice.toJson());
    } else {
      // If document doesn't exist, create a new one
      await invoicesCollection.doc(date).set(bigInvoice.toJson());
    }
  }

  static Future<void> updatePaymentInBigInvoice({
    required String date, // Document ID
    required Payment updatedPayment,
    required int paymentIndex, // Index of the payment in the list
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference invoicesCollection =
        firestore.collection('big_invoices');

    // Fetch the BigInvoice document
    DocumentSnapshot docSnapshot = await invoicesCollection.doc(date).get();

    if (!docSnapshot.exists) {
      throw Exception("Document with date $date does not exist");
    }

    // Convert the document to a BigInvoice object
    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    // Update the specific payment in the list
    if (paymentIndex < 0 || paymentIndex >= bigInvoice.payments.length) {
      throw Exception("Invalid payment index");
    }
    bigInvoice.payments[paymentIndex] = updatedPayment;

    // Update the document in Firestore
    await invoicesCollection.doc(date).set(bigInvoice.toJson());
  }

  // ------------------ FIREBASE HELPERS ------------------

// ✅ 2. Get and increment invoice ID safely (single function)
  static Future<int> getAndIncrementInvoiceId() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference docRef =
        firestore.collection('constants').doc('bills_ids');

    return await firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      int currentId = 0;
      if (!snapshot.exists) {
        transaction.set(docRef, {'bills_ids': 1});
        return 1;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      currentId = (data?['bills_ids'] ?? 0) + 1;

      transaction.update(docRef, {'bills_ids': currentId});

      return currentId;
    });
  }

// ------------------ MAIN FUNCTIONS ------------------

// ✅ 3. Add Invoice to BigInvoice (invoices list only)
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
    final firestore = FirebaseFirestore.instance;

    // 1. جلب ID الفاتورة بشكل تسلسلي
    int invoiceId = await getAndIncrementInvoiceId();

    // 2. إنشاء كائن الفاتورة
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

    // 3. التحديث في Firebase باستخدام الـ Atomic Update
    // الطريقة دي بتضمن إن الـ day يتحدث للاسم الصح حتى لو كان قديم
    DocumentReference docRef = firestore.collection('big_invoices').doc(date);

    try {
      await docRef.set({
        'date': date,
        'day': day, // هنا هينزل الاسم اللي باعتينه Saturday
        'invoices': FieldValue.arrayUnion([newInvoice.toJson()]),
      }, SetOptions(merge: true));

      print('✅ تم إضافة الفاتورة بنجاح ليوم $day');
    } catch (e) {
      print('❌ خطأ في إضافة الفاتورة: $e');
      rethrow;
    }
  }

// 4. Update Invoice (by replacing it in invoices list)
  static Future<void> updateInvoiceInBigInvoices({
    required String date,
    required double differenceAmount,
    required Invoice updatedInvoice,
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot docSnapshot =
        await firestore.collection('big_invoices').doc(date).get();

    if (!docSnapshot.exists) {
      throw Exception("BigInvoice for $date not found");
    }

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    // Find invoice index by id
    int index = bigInvoice.invoices
        .indexWhere((invoice) => invoice.id == updatedInvoice.id);

    if (index == -1) {
      throw Exception("Invoice with ID ${updatedInvoice.id} not found");
    }

    // Replace invoice
    bigInvoice.invoices[index] = updatedInvoice;

    // ✅ Save updated big invoice
    await firestore
        .collection('big_invoices')
        .doc(date)
        .update(bigInvoice.toJson());

    // ✅ Fetch the student using your function
    Studentmodel? student = await FirebaseExams.getStudent(
      updatedInvoice.grade,
      updatedInvoice.studentId,
    );

    if (student != null) {
      // ✅ Update the paidAmount in student model
      for (var sub in student.studentPaidSubscriptions!) {
        if (sub.subscriptionId == updatedInvoice.subscriptionFeeID) {
          sub.paidAmount += differenceAmount;
          break;
        }
      }

      // ✅ Save updated student back to Firestore
      await FirebaseFunctions.getSecondaryCollection(updatedInvoice.grade)
          .doc(updatedInvoice.studentId)
          .update(student.toJson());
    }
  }

  static Future<void> deleteInvoiceFromBigInvoices({
    required String date,
    required Invoice invoice,
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot docSnapshot =
        await firestore.collection('big_invoices').doc(date).get();

    if (!docSnapshot.exists) {
      throw Exception("BigInvoice for $date not found");
    }

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

    // Find invoice index in big invoice
    int index = bigInvoice.invoices.indexWhere((inv) => inv.id == invoice.id);

    if (index == -1) {
      throw Exception("Invoice with ID ${invoice.id} not found");
    }

    // ✅ Remove from big invoices list
    bigInvoice.invoices.removeAt(index);

    await firestore
        .collection('big_invoices')
        .doc(date)
        .update(bigInvoice.toJson());

    // ✅ Now remove it from the student's records
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

      // ✅ حفظ التحديث في Firebase
      await FirebaseFunctions.getSecondaryCollection(invoice.grade)
          .doc(invoice.studentId)
          .update(student.toJson());
    }
  }

  static Future<List<Invoice>> getInvoicesByStudentNumber(
      String studentNumber) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get all big_invoices docs
    QuerySnapshot snapshot = await firestore.collection('big_invoices').get();

    List<Invoice> studentInvoices = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DailyInvoice bigInvoice = DailyInvoice.fromJson(data);

      // Filter invoices for this student number
      var matchingInvoices = bigInvoice.invoices
          .where((invoice) => invoice.studentId == studentNumber)
          .toList();

      studentInvoices.addAll(matchingInvoices);
    }

    return studentInvoices;
  }

  //  ................===============     subscriptions   ==============........................

  static Future<void> createGradeSubscriptionDoc(
      GradeSubscriptionsModel model) async {
    await FirebaseFirestore.instance
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
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();

    // 🔹 Create a temporary document reference just to generate an ID
    final tempId = firestore.collection('temp_ids').doc().id;

    final newSubscription = SubscriptionFee(
      id: tempId,
      subscriptionName: subscriptionName.trim(),
      subscriptionAmount: subscriptionAmount,
    );

    if (!doc.exists) {
      // 🔹 Create the document if it doesn't exist
      final newGrade = GradeSubscriptionsModel(
        gradeName: gradeName,
        subscriptions: [newSubscription],
      );

      await docRef.set(newGrade.toJson());
      return;
    }

    // 🔹 If it exists, append the new subscription
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
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Grade '$gradeName' does not exist.");

    final grade = GradeSubscriptionsModel.fromJson(doc.data()!);

    // 👇 Find by ID instead of name
    final index =
        grade.subscriptions.indexWhere((s) => s.id == updatedSubscription.id);

    if (index == -1) {
      throw Exception(
          "Subscription with ID '${updatedSubscription.id}' not found.");
    }

    // 👇 Replace with updated one
    grade.subscriptions[index] = updatedSubscription;

    await docRef.update({
      'subscriptions': grade.subscriptions.map((e) => e.toJson()).toList(),
    });
  }

  static Future<void> deleteSubscriptionFromGrade(
      String gradeName, String subscriptionId) async {
    final docRef = FirebaseFirestore.instance
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
    final firestore = FirebaseFirestore.instance;

    final docRef = firestore
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    final doc = await docRef.get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['subscriptions'] == null) return null;

    final subscriptions = (data['subscriptions'] as List)
        .map((e) => SubscriptionFee.fromJson(e as Map<String, dynamic>))
        .toList();

    try {
      // 🔍 Find the subscription by ID
      return subscriptions.firstWhere((sub) => sub.id == subscriptionId);
    } catch (e) {
      // Not found
      return null;
    }
  }

  static Stream<GradeSubscriptionsModel?> getGradeSubscriptionsStream(
      String gradeName) {
    final docRef = FirebaseFirestore.instance
        .collection('constants')
        .doc('grades_subscriptions')
        .collection('grades')
        .doc(gradeName);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return GradeSubscriptionsModel.fromJson(snapshot.data()!);
    });
  }

  // passwords============

  static Future<bool> verifyPassword(String enteredPassword) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('constants').doc('password');
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({'password': '0'});
        return enteredPassword == '0';
      }

      final data = doc.data();
      final savedPassword = data?['password'] ?? '0';

      if (data == null || !data.containsKey('password')) {
        await docRef.set({'password': '0'});
      }

      // ✅ Finally, compare passwords
      return enteredPassword == savedPassword;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  static Future<bool> changePassword(String newPassword) async {
    try {
      await FirebaseFirestore.instance
          .collection('constants')
          .doc('password')
          .update({'password': newPassword});
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // =======================================================================
  // Absence Management Functions
  // =======================================================================

  /// Deletes an absence from the "absences" subcollection.
  static Future<void> deleteAbsenceFromSubcollection(
      String day, String magmo3aId, String absenceDate) async {
    try {
      CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);
      DocumentReference<Magmo3amodel> magmo3aDocRef =
          dayCollection.doc(magmo3aId);
      DocumentSnapshot<Magmo3amodel> magmo3aSnapshot =
          await magmo3aDocRef.get();

      if (!magmo3aSnapshot.exists) {
        throw Exception("Group (Magmo3a) not found.");
      }

      CollectionReference<AbsenceModel> absencesSubcollectionRef =
          magmo3aDocRef.collection('absences').withConverter<AbsenceModel>(
                fromFirestore: (snapshot, _) =>
                    AbsenceModel.fromJson(snapshot.data()!),
                toFirestore: (value, _) => value.toJson(),
              );

      await absencesSubcollectionRef.doc(absenceDate).delete();
    } catch (e) {
      print("Error deleting absence: $e");
    }
  }

  /// Updates an absence record by its date in the subcollection with merge option.
  static Future<void> updateAbsenceByDateInSubcollection(
    String day,
    String magmo3aId,
    String absenceDate,
    AbsenceModel updatedAbsence,
  ) async {
    try {
      CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);
      DocumentReference<Magmo3amodel> magmo3aDocRef =
          dayCollection.doc(magmo3aId);
      DocumentSnapshot<Magmo3amodel> magmo3aSnapshot =
          await magmo3aDocRef.get();

      if (!magmo3aSnapshot.exists) {
        throw Exception("Group (Magmo3a) not found.");
      }

      CollectionReference<AbsenceModel> absencesSubcollectionRef =
          magmo3aDocRef.collection('absences').withConverter<AbsenceModel>(
                fromFirestore: (snapshot, _) =>
                    AbsenceModel.fromJson(snapshot.data()!),
                toFirestore: (value, _) => value.toJson(),
              );

      DocumentReference<AbsenceModel> absenceDocRef =
          absencesSubcollectionRef.doc(absenceDate);

      // Use set with merge: true to update fields without overwriting entire document
      await absenceDocRef.set(
        updatedAbsence,
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Error updating absence: $e");
      rethrow; // Rethrow to allow caller to handle the error
    }
  }

  static Future<QuerySnapshot<Studentmodel>> getStudentsByGroupIdOnce(
      String grade, String groupId) async {
    var collection = getSecondaryCollection(grade);

    final query = collection
        .where("hisGroupsId", arrayContains: groupId)
        .withConverter<Studentmodel>(
          fromFirestore: (snap, _) => Studentmodel.fromJson(snap.data()!),
          toFirestore: (student, _) => student.toJson(),
        );

    return await query.get(); // fetch once
  }

  /// Fetches an absence record by its date.
  ///
  ///
  ///
  /// make this streaaaaam
  ///
  static Stream<AbsenceModel?> getAbsenceByDateStream(
      String day, String groupId, String date) {
    try {
      return FirebaseFirestore.instance
          .collection(day)
          .doc(groupId)
          .collection('absences')
          .doc(date)
          .snapshots()
          .map((docSnapshot) {
        if (docSnapshot.exists) {
          return AbsenceModel.fromJson(
              docSnapshot.data() as Map<String, dynamic>);
        } else {
          return null;
        }
      });
    } catch (e) {
      print("Error fetching absence record stream: $e");
      // Return an empty stream on error
      return Stream.value(null);
    }
  }

  static Future<AbsenceModel?> getAbsenceByDateOnce(
      String day, String groupId, String date) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(day)
          .doc(groupId)
          .collection('absences')
          .doc(date)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return AbsenceModel.fromJson(
            docSnapshot.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching absence record once: $e");
      return null;
    }
  }

  // =======================================================================
  // Student Management Functions
  // =======================================================================

  /// Fetches a student by their ID from a specific grade.
  static Future<Studentmodel?> getStudentById(
      String grade, String studentId) async {
    try {
      CollectionReference<Studentmodel> studentsCollection =
          getSecondaryCollection(grade);
      DocumentSnapshot<Studentmodel> studentSnapshot =
          await studentsCollection.doc(studentId).get();

      if (studentSnapshot.exists) {
        return studentSnapshot.data();
      } else {
        print("Student not found.");
        return null;
      }
    } catch (e) {
      print("Error fetching student: $e");
      return null;
    }
  }
}
