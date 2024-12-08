import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';
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

  /// Deletes a `Magmo3aModel` document from a specific day's collection
  static Future<void> deleteMagmo3aFromDay(String day, String documentId) async {
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
  static Future<void> addStudentToCollection(
      String grade, Studentmodel studentModel) async {
    CollectionReference<Studentmodel> collection =
    getSecondaryCollection(grade);

    DocumentReference<Studentmodel> newDocRef = collection.doc();
    studentModel.id = newDocRef.id;

    await newDocRef.set(studentModel);
  }


 static Future<void> resetAttendanceForAllStudents() async {
    List<String> grades = ['1 secondary', '2 secondary', '3 secondary'];

    for (var grade in grades) {
      // Get the collection for each grade
      CollectionReference<Studentmodel> collection = getSecondaryCollection(grade);

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
    CollectionReference<Studentmodel> collection = getSecondaryCollection(grade);
    await collection.doc(studentId).update(updatedStudentModel.toJson());
  }

  /// Retrieves all students for a specific grade as a stream
  static Stream<List<Studentmodel>> getAllStudentsByGrade(String grade) {
    CollectionReference<Studentmodel> collection = getSecondaryCollection(grade);
    return collection.snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves students filtered by first day ID
  static Stream<QuerySnapshot<Studentmodel>> getStudentsByFirstDayId(
      String grade, String firstdayid) {
    var collection =
    getSecondaryCollection(grade); // Get the collection based on grade
    return collection.where("firstdayid", isEqualTo: firstdayid).snapshots();
  }

  /// Retrieves students filtered by Second day ID
  static Stream<QuerySnapshot<Studentmodel>> getStudentsBySecondDayId(
      String grade, String seconddayid) {
    var collection =
    getSecondaryCollection(grade); // Get the collection based on grade
    return collection.where("seconddayid", isEqualTo: seconddayid).snapshots();
  }

  /// Retrieves students filtered by Third day ID
  static Stream<QuerySnapshot<Studentmodel>> getStudentsByThirdDayId(
      String grade, String thirddayid) {
    var collection =
    getSecondaryCollection(grade); // Get the collection based on grade
    return collection.where("thirddayid", isEqualTo: thirddayid).snapshots();
  }

  /// Retrieves students filtered by Forth day ID
  static Stream<QuerySnapshot<Studentmodel>> getStudentsByForthDayId(
      String grade, String forthdayid) {
    var collection =
    getSecondaryCollection(grade); // Get the collection based on grade
    return collection.where("forthdayid", isEqualTo: forthdayid).snapshots();
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
      fromFirestore: (snapshot, _) =>
          Usermodel.fromJson(snapshot.data()!),
      toFirestore: (value, _) => value.tojson(),
    );
  }
}
