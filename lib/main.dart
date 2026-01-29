
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management_system/auth/subscription_expired_screen.dart';

import 'auth/login_screen.dart';
import 'auth/noInternetConnection.dart';
import 'auth/register_screen.dart';
import 'auth/update_required_screen.dart';
import 'bloc/observer.dart';
import 'constants.dart';
import 'firebase/firebase_options.dart';
import 'home.dart';
import 'models/admin/teacher.dart';
import 'pages/AllStudentPage.dart';
import 'provider.dart';

void main() async {
  Bloc.observer = MyBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(/* التيم بتاعك */),
      // نستخدم StreamBuilder لمراقبة النت لحظة بلحظة
      home: StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          final connectivityResult = snapshot.data;

          // التحقق من وجود اتصال حقيقي
          bool isConnected = connectivityResult != null &&
              !connectivityResult.contains(ConnectivityResult.none);

          // في حالة عدم وجود داتا (بداية التشغيل) نقوم بعمل فحص سريع للـ ConnectionState
          if (snapshot.connectionState == ConnectionState.waiting) {
            // يمكن استدعاء دالة تشيك سريعة أو ترك المستخدم يمر للـ AuthGate
            // لكن الأفضل التأكد من وجود قيمة أولية
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (!isConnected) {
            return const NoInternetScreen(); // صفحة النت مقطوع
          }

          // لو النت موجود، ادخل على بوابة التأكد من الهوية والاشتراك
          return AuthGate();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/HomeScreen': (context) => const Homescreen(),
        '/StudentsTab': (context) => const AllStudentsTab(),
        '/expired': (context) => SubscriptionExpiredScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // جلب بيانات الإصدار وبيانات المدرس معاً في طلب واحد
        return FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('app_settings')
                .doc('version_info')
                .get(),
            FirebaseFirestore.instance
                .collection('teachers')
                .doc(snapshot.data!.uid)
                .get(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> combinedSnapshot) {
            if (combinedSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            // التأكد من وصول البيانات
            if (!combinedSnapshot.hasData || combinedSnapshot.hasError) {
              return LoginScreen();
            }

            final versionDoc = combinedSnapshot.data![0] as DocumentSnapshot;
            final teacherDoc = combinedSnapshot.data![1] as DocumentSnapshot;

            // 1. أولاً: فحص الإصدار (Force Update)
            String minVersion = versionDoc.exists
                ? (versionDoc['min_version'] ?? "1.0.0")
                : "1.0.0";
            String downloadUrl =
                versionDoc.exists ? (versionDoc['download_url'] ?? "") : "";

            if (AppConstants.currentAppVersion != minVersion) {
              return UpdateRequiredScreen(updateUrl: downloadUrl);
            }

            // 2. ثانياً: فحص بيانات المدرس والاشتراك
            if (teacherDoc.exists) {
              Teacher teacher = Teacher.fromJson(
                  teacherDoc.data() as Map<String, dynamic>, teacherDoc.id);

              // تحديث الـ Provider
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<TeacherProvider>(context, listen: false)
                    .setTeacher(teacher);
              });

              // فحص الصلاحية (الوقت) والحالة
              if (teacher.subscriptionEndTime.isAfter(DateTime.now()) &&
                  teacher.isActive) {
                return const Homescreen();
              } else {
                return const SubscriptionExpiredScreen();
              }
            }

            return LoginScreen();
          },
        );
      },
    );
  }
}