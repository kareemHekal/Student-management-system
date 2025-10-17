import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/Big invoice.dart';
import '../models/Invoice.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';
import '../models/payment.dart';
import '../models/usermodel.dart';

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
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    return dayCollection
        .where("userid", isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves all documents in a specific day's collection filtered by grade
  static Stream<List<Magmo3amodel>> getAllDocsFromDayWithGrade(
      String day, String grade) {
    CollectionReference<Magmo3amodel> dayCollection = getDayCollection(day);
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      throw Exception("No user is currently logged in.");
    }

    return dayCollection
        .where("userid", isEqualTo: currentUserId)
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

  static Future<void> resetAttendanceForAllStudents() async {
    List<String> grades = [];

    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();
    grades = fetchedGrades;

    for (var grade in grades) {
      // Get the collection for each grade
      CollectionReference<Studentmodel> collection =
          getSecondaryCollection(grade);

      // Get all students in the grade collection
      QuerySnapshot snapshot = await collection.get();

      // Iterate through each student and update attendance fields
      for (var doc in snapshot.docs) {
        // Explicitly cast the data to a Studentmodel object
        Studentmodel student = doc.data() as Studentmodel;

        // Update attendance fields (set to 0)
        await collection.doc(doc.id).update({
          'numberOfAbsentDays': 0,
          'numberOfAttendantDays': 0,
        });

        print('Updated attendance for student: ${student.name}');
      }
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

  /// Deletes all documents in a specific grade's collection
  static Future<void> deleteCollection(String grade) async {
    final collectionRef = FirebaseFirestore.instance.collection(grade);
    final snapshot = await collectionRef.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> addGradeToList(String newGrade) async {
    try {
      // Reference to the 'constants' collection and the 'grades' document
      DocumentReference gradesDoc =
          FirebaseFirestore.instance.collection('constants').doc('grades');

      // Get the current document data
      DocumentSnapshot snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        // Get the current list of grades
        List<dynamic> gradesList = List.from(snapshot[
            'grades']); // Clone the list to prevent modification of the original one

        // Add the new grade to the list
        gradesList.add(newGrade);

        // Update the 'grades' field in the document with the modified list
        await gradesDoc.update({'grades': gradesList});

        print("Grade added successfully.");
      } else {
        print("Document does not exist.");
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

      // 1️⃣ Update the grade name in constants/grades list
      DocumentReference gradesDoc =
          firestore.collection('constants').doc('grades');
      DocumentSnapshot snapshot = await gradesDoc.get();

      if (snapshot.exists) {
        List<dynamic> gradesList = List.from(snapshot['grades']);
        if (gradesList.contains(oldGrade)) {
          int index = gradesList.indexOf(oldGrade);
          gradesList[index] = newGrade;
          await gradesDoc.update({'grades': gradesList});
          print('✅ Grade name updated in constants.');
        } else {
          print('⚠️ Old grade not found in constants list.');
        }
      }

      // 2️⃣ Copy all students from old collection to new collection, update grade field
      final oldCollection = getSecondaryCollection(oldGrade);
      final newCollection = getSecondaryCollection(newGrade);

      final oldStudentsSnapshot = await oldCollection.get();
      for (var doc in oldStudentsSnapshot.docs) {
        Studentmodel student = doc.data();
        student.grade = newGrade; // Update grade field
        await newCollection.doc(student.id).set(student);
      }

      // 3️⃣ Delete old grade collection after copying
      for (var doc in oldStudentsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Students moved and old collection deleted.');

      // 4️⃣ Go through all day collections and update magmo3a documents that have this grade
      final allDays = [
        "Saturday",
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
      ];

      for (var day in allDays) {
        final dayCollection = getDayCollection(day);
        final daySnapshot = await dayCollection.get();
        for (var doc in daySnapshot.docs) {
          Magmo3amodel magmo3a = doc.data();
          if (magmo3a.grade == oldGrade) {
            magmo3a.grade = newGrade;
            await dayCollection.doc(magmo3a.id).set(magmo3a);
          }
        }
      }

      print('✅ All magmo3a groups updated to new grade.');

      print('🎉 Grade renamed successfully from "$oldGrade" to "$newGrade".');
    } catch (e) {
      print('❌ Error renaming grade: $e');
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

  // =============================== Authentication Functions ===============================

  /// Creates a new account in Firebase and saves the user data
  static createAccount(
    String emailAddress,
    String password, {
    required Function onSucsses,
    required Function onEror,
    required String Username,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      credential.user?.sendEmailVerification();
      Usermodel user = Usermodel(
          id: credential.user!.uid, name: Username, email: emailAddress);
      addUser(user);
      onSucsses();
    } on FirebaseAuthException catch (e) {
      onEror(e.message);
    }
  }

  /// Logs in the user and verifies their email
  static login(String emailAddress, String password,
      {required String Username,
      required Function onSucsses,
      required Function onEror}) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);
      if (credential.user?.emailVerified == true) {
        onSucsses();
      }
    } on FirebaseAuthException catch (e) {
      onEror(e.message);
    }
  }

  /// Reads user data from the `users` collection
  static Future<Usermodel?> ReadUserData() async {
    var collection = getUsersCollection();
    DocumentSnapshot<Usermodel> docUser =
        await collection.doc(FirebaseAuth.instance.currentUser!.uid).get();
    return docUser.data();
  }

  /// Adds a new user to the `users` collection
  static addUser(Usermodel user) {
    var colliction = getUsersCollection();
    var docref = colliction.doc(user.id);
    docref.set(user);
  }

  /// Returns a reference to the `users` collection
  static CollectionReference<Usermodel> getUsersCollection() {
    return FirebaseFirestore.instance
        .collection("users")
        .withConverter<Usermodel>(
          fromFirestore: (snapshot, _) => Usermodel.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.tojson(),
        );
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

// 1. Get the current invoice ID
  static Future<int> getNextInvoiceId() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot docSnapshot =
        await firestore.collection('constants').doc('bills_ids').get();

    if (!docSnapshot.exists) {
      throw Exception("bills_ids document not found!");
    }

    Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
    return data['bills_ids'] ?? 0;
  }

// 2. Increment invoice ID after success
  static Future<void> incrementInvoiceId(int newValue) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore
        .collection('constants')
        .doc('bills_ids')
        .update({'bills_ids': newValue});
  }

// ------------------ MAIN FUNCTIONS ------------------

// 3. Add Invoice to BigInvoice (invoices list only)
  static Future<void> addInvoiceToBigInvoices({
    required String date,
    required String day,
    required String grade,
    required double amount,
    required String description,
    required String studentId,
    required String studentName,
    required String phoneNumber,
    required String motherPhone,
    required String fatherPhone,
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get next invoice ID
    int invoiceId = await getNextInvoiceId();

    // Create invoice with assigned ID
    Invoice newInvoice = Invoice(
      id: invoiceId.toString(),
      studentId: studentId,
      studentName: studentName,
      studentPhoneNumber: phoneNumber,
      momPhoneNumber: motherPhone,
      dadPhoneNumber: fatherPhone,
      grade: grade,
      amount: amount,
      description: description,
      dateTime: DateTime.now(),
    );

    // Check if big invoice exists for this date
    DocumentSnapshot docSnapshot =
        await firestore.collection('big_invoices').doc(date).get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      BigInvoice bigInvoice = BigInvoice.fromJson(data);

      // Add invoice to list
      bigInvoice.invoices.add(newInvoice);

      await firestore
          .collection('big_invoices')
          .doc(date)
          .update(bigInvoice.toJson());
    } else {
      // Create new BigInvoice with this invoice
      BigInvoice bigInvoice = BigInvoice(
        date: date,
        day: day,
        invoices: [newInvoice],
        payments: [],
      );

      await firestore
          .collection('big_invoices')
          .doc(date)
          .set(bigInvoice.toJson());
    }

    // Increment invoice ID only after success
    await incrementInvoiceId(invoiceId + 1);
  }

// 4. Update Invoice (by replacing it in invoices list)
  static Future<void> updateInvoiceInBigInvoices({
    required String date,
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

    await firestore
        .collection('big_invoices')
        .doc(date)
        .update(bigInvoice.toJson());
  }

  static Future<void> deleteInvoiceFromBigInvoices({
    required String date,
    required String invoiceId,
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
    int index =
        bigInvoice.invoices.indexWhere((invoice) => invoice.id == invoiceId);

    if (index == -1) {
      throw Exception("Invoice with ID $invoiceId not found");
    }

    // Remove invoice
    bigInvoice.invoices.removeAt(index);

    await firestore
        .collection('big_invoices')
        .doc(date)
        .update(bigInvoice.toJson());
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

  // passwords============

  static Future<bool> verifyPassword(String enteredPassword) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('constants')
          .doc('password')
          .get();
      final savedPassword = doc.data()?['password'] ?? '';

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
