import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Big invoice.dart';
import '../models/Invoice.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';
import '../models/absence_model.dart';
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

  static Future<void> editMagmo3aInDay(String oldDay,
      String oldGrade,
      Magmo3amodel updatedMagmo3a,) async {
    final newDay = updatedMagmo3a.days;

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
      final student = data is Studentmodel
          ? data
          : Studentmodel.fromJson(data as Map<String, dynamic>);

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
  static Future<void> deleteMagmo3aFromDay(
      String day, String documentId) async {
    await getDayCollection(day).doc(documentId).delete();
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
  static Future<void> deleteAbsencesSubcollection(String day) async {
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
    try {
      final firestore = FirebaseFirestore.instance;
      final grades = await FirebaseFunctions.getGradesList();

      for (final grade in grades) {
        final collection = getSecondaryCollection(grade); // Query<Studentmodel>
        final snapshot = await collection.get();

        if (snapshot.docs.isEmpty) {
          print("⚠️ No students found for grade: $grade");
          continue;
        }

        print("🟢 Processing ${snapshot.docs.length} students in $grade...");

        const batchSize = 100;
        final studentDocs = snapshot.docs;

        for (var i = 0; i < studentDocs.length; i += batchSize) {
          final batch = firestore.batch();
          final chunk = studentDocs.skip(i).take(batchSize);

          for (final doc in chunk) {
            // Use typed model instead of casting
            final student = doc.data();

            final newAbsence = AbsenceModel(
              monthName: monthName,
              attendedDays: student.countingAttendedDays ?? [],
              absentDays: student.countingAbsentDays ?? [],
            );

            final updatedAbsences = [
              if (student.absencesNumbers != null)
                ...student.absencesNumbers!.map((e) => e.toJson()),
              newAbsence.toJson(),
            ];

            batch.update(collection.doc(doc.id), {
              'absencesNumbers': updatedAbsences,
              'countingAttendedDays': [],
              'countingAbsentDays': [],
            });
          }

          await batch.commit();
          print("✅ Committed batch ${i ~/ batchSize + 1} for grade $grade");

          // Small delay to reduce Firestore load
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      print("🎉 Finished saving month '$monthName' for all grades.");
    } catch (e, stack) {
      print("❌ Error in saveMonthAndStartNew: $e");
      print(stack);
      rethrow;
    }
  }

  static Future<void> resetGradeSubscriptionsAndAbsences(
      String gradeName) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final docRef = firestore
          .collection('constants')
          .doc('grades_subscriptions')
          .collection('grades')
          .doc(gradeName);

      final doc = await docRef.get();
      if (!doc.exists) {
        print("⚠️ Grade $gradeName does not exist.");
        return;
      }

      // 🔹 1. Clear all grade-level subscriptions
      await docRef.update({'subscriptions': []});
      print("✅ Grade-level subscriptions for '$gradeName' cleared.");

      // 🔹 2. Get all students in that grade
      final allStudents = await getAllStudentsByGrade_future(gradeName);

      print("📦 Found ${allStudents.length} students in grade $gradeName.");

      // 🔹 3. Prepare batch updates for students
      const batchSize = 400; // <= limit to avoid Firestore overload
      for (int i = 0; i < allStudents.length; i += batchSize) {
        final batch = firestore.batch();

        final chunk = allStudents.skip(i).take(batchSize);
        for (final student in chunk) {
          final studentRef = getSecondaryCollection(gradeName).doc(student.id);

          batch.update(studentRef, {
            'studentPaidSubscriptions': [],
            'studentExamsGrades': [],
            'absencesNumbers': [],
            'countingAttendedDays': [],
            'countingAbsentDays': [],
            'notes': [],
          });
        }

        await batch.commit();
        print(
            "✅ Updated ${chunk.length} students [${i + 1}-${i + chunk.length}]");
        await Future.delayed(const Duration(milliseconds: 300)); // small delay
      }

      print(
          "✅ All students in '$gradeName' had their subscriptions and absences reset.");

      // 🔹 4. Delete all exams for this grade (safe delete)
      final examsDocRef = firestore.collection('exams').doc(gradeName);

      final examsDoc = await examsDocRef.get();
      if (examsDoc.exists) {
        await examsDocRef.delete();
        print("✅ Exams for grade '$gradeName' deleted successfully.");
      } else {
        print("⚠️ No exams found for grade '$gradeName'.");
      }

      print("🎯 Completed reset for grade '$gradeName'.");
    } catch (e, stack) {
      print("❌ Error resetting grade '$gradeName': $e");
      print(stack);
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
      final firestore = FirebaseFirestore.instance;

      // 1️⃣ Update grade name in constants/grades list
      final DocumentReference gradesDoc =
          firestore.collection('constants').doc('grades');
      final DocumentSnapshot gradesSnapshot = await gradesDoc.get();

      if (gradesSnapshot.exists) {
        List<dynamic> gradesList = List.from(gradesSnapshot['grades']);
        if (gradesList.contains(oldGrade)) {
          int index = gradesList.indexOf(oldGrade);
          gradesList[index] = newGrade;
          await gradesDoc.update({'grades': gradesList});
          print('✅ Grade name updated in constants.');
        } else {
          print('⚠️ Old grade not found in constants list.');
        }
      }

      // 2️⃣ Copy all students to new collection, update grade field
      final oldCollection =
          getSecondaryCollection(oldGrade); // typed Collection<Studentmodel>
      final newCollection =
          getSecondaryCollection(newGrade); // typed Collection<Studentmodel>
      final oldStudentsSnapshot = await oldCollection.get();

      for (var doc in oldStudentsSnapshot.docs) {
        Studentmodel student = doc.data();
        student.grade = newGrade;
        await newCollection.doc(student.id).set(student); // pass model directly
      }

      // 3️⃣ Delete old grade collection
      for (var doc in oldStudentsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Students moved and old collection deleted.');

      // 4️⃣ Update magmo3a documents in all day collections
      final allDays = [
        "Saturday",
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday"
      ];

      for (var day in allDays) {
        final dayCollection =
            getDayCollection(day); // typed Collection<Magmo3amodel>
        final daySnapshot = await dayCollection.get();

        for (var doc in daySnapshot.docs) {
          Magmo3amodel magmo3a = doc.data();
          if (magmo3a.grade == oldGrade) {
            magmo3a.grade = newGrade;
            await dayCollection
                .doc(magmo3a.id)
                .set(magmo3a); // pass model directly
          }
        }
      }
      print('✅ All magmo3a groups updated.');

      // 5️⃣ Rename grade subscription document
      final oldSubDocRef = firestore
          .collection('constants')
          .doc('grades_subscriptions')
          .collection('grades')
          .doc(oldGrade);

      final oldSubSnapshot = await oldSubDocRef.get();
      if (oldSubSnapshot.exists) {
        final oldModel =
            GradeSubscriptionsModel.fromJson(oldSubSnapshot.data()!);
        oldModel.gradeName = newGrade;

        final newSubDocRef = firestore
            .collection('constants')
            .doc('grades_subscriptions')
            .collection('grades')
            .doc(newGrade);

        await newSubDocRef.set(oldModel.toJson()); // ✅ هذا صحيح
        await oldSubDocRef.delete();
        print('✅ Grade subscription renamed.');
      } else {
        print('⚠️ No subscription document found for $oldGrade.');
      }

      // 6️⃣ Rename exam document
      final oldExamDocRef = firestore.collection('exams').doc(oldGrade);
      final oldExamSnapshot = await oldExamDocRef.get();

      if (oldExamSnapshot.exists) {
        final oldExamData = oldExamSnapshot.data();
        final newExamDocRef = firestore.collection('exams').doc(newGrade);

        if (oldExamData != null) {
          final updatedExamData = Map<String, dynamic>.from(oldExamData);
          updatedExamData['gradeName'] = newGrade;
          await newExamDocRef.set(updatedExamData);
        }

        await oldExamDocRef.delete();
        print('✅ Exam document renamed.');
      } else {
        print('⚠️ No exam document found for $oldGrade.');
      }

      print('🎉 Grade renamed successfully from "$oldGrade" to "$newGrade".');
    } catch (e, stack) {
      print('❌ Error renaming grade: $e');
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

  static Future<void> addBigInvoice(BigInvoice bigInvoice) async {
    // Reference to the Firestore collection
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference invoicesCollection =
        firestore.collection('big_invoices');

    // Create or update the document with the formatted date as the doc ID
    await invoicesCollection.doc(bigInvoice.date).set(bigInvoice.toJson());
  }

  static Future<void> updateBigInvoice(
      String date, BigInvoice bigInvoice) async {
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
    BigInvoice bigInvoice = BigInvoice.fromJson(data);

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
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // ✅ Get and increment ID atomically
    int invoiceId = await getAndIncrementInvoiceId();

    // ✅ Create invoice with assigned ID
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

    // ✅ Check if big invoice exists for this date
    DocumentReference docRef = firestore.collection('big_invoices').doc(date);

    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      BigInvoice bigInvoice = BigInvoice.fromJson(data);

      bigInvoice.invoices.add(newInvoice);

      await docRef.update(bigInvoice.toJson());
    } else {
      BigInvoice bigInvoice = BigInvoice(
        date: date,
        day: day,
        invoices: [newInvoice],
        payments: [],
      );

      await docRef.set(bigInvoice.toJson());
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
    BigInvoice bigInvoice = BigInvoice.fromJson(data);

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
    BigInvoice bigInvoice = BigInvoice.fromJson(data);

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
      BigInvoice bigInvoice = BigInvoice.fromJson(data);

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

  static Future<void> updateSubscriptionInGrade(String gradeName,
      SubscriptionFee updatedSubscription,) async {
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

  static Future<void> deleteSubscriptionFromGrade(String gradeName,
      String subscriptionId) async {
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
}

