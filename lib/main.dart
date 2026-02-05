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

import 'auth/grace_period_end_time.dart';
import 'auth/login_screen.dart';
import 'auth/noInternetConnection.dart';
import 'auth/register_screen.dart';
import 'auth/renew_subscription_page.dart';
import 'auth/update_required_screen.dart';
import 'bloc/observer.dart';
import 'constants.dart';
import 'firebase/firebase_options.dart';
import 'home.dart';
import 'models/admin/teacher.dart';
import 'pages/all_students/AllStudentPage.dart';
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
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // تفعيل الحفظ على الموبايل
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // مساحة تخزين مفتوحة
  );
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
      builder: (context, child) {
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final connectivityResult = snapshot.data;

            // التحقق من الاتصال
            bool isConnected = connectivityResult != null &&
                !connectivityResult.contains(ConnectivityResult.none);

            // 1. لو لسه بيحمل الداتا لأول مرة
            if (snapshot.connectionState == ConnectionState.waiting) {
              return child!; // خليه يكمل تحميل الشاشة اللي هو فيها
            }

            // 2. لو مفيش نت (اطرده فوراً)
            if (!isConnected) {
              return const NoInternetScreen();
            }

            // 3. لو فيه نت، اعرض التطبيق الطبيعي (الـ child اللي هو الـ Navigator)
            return child!;
          },
        );
      },
      home: const AuthGate(), // الـ AuthGate تبدأ شغلها هنا لو فيه نت
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/HomeScreen': (context) => const Homescreen(),
        '/StudentsTab': (context) => const AllStudentsTab(),
        '/expired': (context) => SubscriptionExpiredScreen(),
        '/subscriptionPlansPage': (context) => SubscriptionPlansPage(),
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

        final user = snapshot.data;
        if (user == null) return LoginScreen();

        return FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection('app_settings')
                .doc('version_info')
                .get(),
            FirebaseFirestore.instance
                .collection('teachers')
                .doc(user.uid)
                .get(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> combinedSnapshot) {
            if (combinedSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (!combinedSnapshot.hasData || combinedSnapshot.hasError) {
              return LoginScreen();
            }

            final versionDoc = combinedSnapshot.data?[0] as DocumentSnapshot?;
            final teacherDoc = combinedSnapshot.data?[1] as DocumentSnapshot?;

            if (versionDoc == null ||
                teacherDoc == null ||
                !teacherDoc.exists) {
              return LoginScreen();
            }

            // 1. فحص الإصدار (Force Update)
            final vData = versionDoc.data() as Map<String, dynamic>?;
            String minVersion = vData?['min_version'] ?? "1.0.0";
            if (AppConstants.currentAppVersion != minVersion) {
              return UpdateRequiredScreen(
                  updateUrl: vData?['download_url'] ?? "");
            }

            // 2. فحص بيانات المدرس
            final tData = teacherDoc.data() as Map<String, dynamic>;
            Teacher teacher = Teacher.fromJson(tData, teacherDoc.id);

            // تحديث الـ Provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Provider.of<TeacherProvider>(context, listen: false)
                    .setTeacher(teacher);
              }
            });

            // نستخدم FutureBuilder داخلي لحساب الحد الأقصى للطلاب ديناميكياً
            return FutureBuilder<int>(
              future: teacher.getTotalAllowedStudents(),
              builder: (context, studentLimitSnapshot) {
                if (studentLimitSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }

                final int totalAllowed = studentLimitSnapshot.data ?? 0;
                final now = DateTime.now();

                // --- منطق الحماية والـ 3 أيام (The Core Logic) ---

                // أولاً: إذا كانت هناك فترة سماح مخزنة وانتهت (المنع النهائي)
                if (teacher.gracePeriodEndTime != null &&
                    now.isAfter(teacher.gracePeriodEndTime!)) {
                  return const SubscriptionExpiredScreen();
                }

                // ثانياً: إذا كانت فترة السماح مخزنة ولسه شغالة (اعرض صفحة التنبيه إجباري)
                if (teacher.gracePeriodEndTime != null &&
                    now.isBefore(teacher.gracePeriodEndTime!)) {
                  return GracePeriodAlertScreen(
                      graceEndDate: teacher.gracePeriodEndTime!);
                }

                // ثالثاً: لو الخانة null، نفحص هل هو سليم أم تخطى الحدود؟
                bool isTimeValid = teacher.subscriptionEndTime.isAfter(now) &&
                    teacher.isActive;
                bool isCountValid = teacher.currentStudentCount <= totalAllowed;

                if (isTimeValid && isCountValid) {
                  // المدرس سليم تماماً
                  return const Homescreen();
                } else {
                  // حصلت مشكلة (وقت أو عدد) والخانة لسه null -> نبدأ الـ 3 أيام
                  DateTime newGraceEnd = now.add(const Duration(days: 3));

                  // تحديث الداتابيز
                  FirebaseFirestore.instance
                      .collection('teachers')
                      .doc(teacher.id)
                      .update({
                    'gracePeriodEndTime': newGraceEnd.toIso8601String(),
                  });

                  return GracePeriodAlertScreen(graceEndDate: newGraceEnd);
                }
              },
            );
          },
        );
      },
    );
  }
}