import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }
  // ------------------

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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

        // استخدام ?. للتأكد من وجود المستخدم قبل الوصول لـ uid
        final user = snapshot.data;

        if (user == null) {
          return LoginScreen();
        }

        return FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('app_settings')
                .doc('version_info')
                .get(),
            FirebaseFirestore.instance
                .collection('teachers')
                .doc(user.uid) // شلنا الـ ! واستخدمنا الـ user المؤمن
                .get(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> combinedSnapshot) {
            if (combinedSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            // التحقق من وجود البيانات ومن عدم حدوث خطأ
            if (!combinedSnapshot.hasData ||
                combinedSnapshot.hasError ||
                combinedSnapshot.data == null ||
                combinedSnapshot.data!.length < 2) {
              return LoginScreen();
            }

            // الوصول للبيانات بشكل آمن
            final versionDoc = combinedSnapshot.data?[0] as DocumentSnapshot?;
            final teacherDoc = combinedSnapshot.data?[1] as DocumentSnapshot?;

            // لو ملفات الداتا مش موجودة أصلاً في الداتابيز
            if (versionDoc == null || teacherDoc == null) {
              return LoginScreen();
            }

            // 1. فحص الإصدار (Force Update)
            String minVersion = "1.0.0";
            String downloadUrl = "";

            if (versionDoc.exists) {
              final vData = versionDoc.data() as Map<String, dynamic>?;
              minVersion = vData?['min_version'] ?? "1.0.0";
              downloadUrl = vData?['download_url'] ?? "";
            }

            if (AppConstants.currentAppVersion != minVersion) {
              return UpdateRequiredScreen(updateUrl: downloadUrl);
            }

            // 2. فحص بيانات المدرس والاشتراك
            if (teacherDoc.exists) {
              final tData = teacherDoc.data() as Map<String, dynamic>?;

              if (tData != null) {
                Teacher teacher = Teacher.fromJson(tData, teacherDoc.id);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // حماية إضافية للـ Provider
                  if (context.mounted) {
                    Provider.of<TeacherProvider>(context, listen: false)
                        .setTeacher(teacher);
                  }
                });

                if (teacher.subscriptionEndTime.isAfter(DateTime.now()) &&
                    teacher.isActive) {
                  return const Homescreen();
                } else {
                  return const SubscriptionExpiredScreen();
                }
              }
            }

            return LoginScreen();
          },
        );
      },
    );
  }
}