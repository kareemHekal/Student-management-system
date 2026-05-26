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
import 'pages/payment/renew_subscription_page.dart';
import 'auth/update_required_screen.dart';
import 'bloc/observer.dart';
import 'constants.dart';
import 'firebase/firebase_options.dart';
import 'home.dart';
import 'models/admin/teacher.dart';
import 'pages/all_students/AllStudentPage.dart';
import 'provider.dart';

import 'dart:async';
import 'package:student_management_system/firebase/firebase_functions.dart'; // تأكد من المسار

// 1. تعريف المفاتيح العالمية للوصول للـ Context في أي وقت
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  Bloc.observer = MyBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } else {
    Firebase.app();
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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
      // 3. ربط المفاتيح هنا
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final connectivityResult = snapshot.data;
            bool isConnected = connectivityResult != null &&
                !connectivityResult.contains(ConnectivityResult.none);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return child!;
            }

            if (!isConnected) {
              return const NoInternetScreen();
            }

            return child!;
          },
        );
      },
      home: const AuthGate(),
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

            // ---------------------------------------------------------
            // المنطقة السحرية: هنا نضمن أن كل شيء جاهز
            // ---------------------------------------------------------
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                // أ: تحديث البروفايدر
                Provider.of<TeacherProvider>(context, listen: false)
                    .setTeacher(teacher);

                // ب: فحص المدفوعات المعلقة
                FirebaseFunctions.checkAndResolvePendingPayment(
                    user.uid, context);

                // ج: معالجة مكافآت الإحالة المعلقة (لو حد استخدم كود الدعوة)
                FirebaseFunctions.processReferralRewards(user.uid);
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

                bool isTimeValid = teacher.subscriptionEndTime.isAfter(now) &&
                    teacher.isActive;
                bool isCountValid = teacher.currentStudentCount <= totalAllowed;

                if (isTimeValid && isCountValid) {
                  // المدرس سليم تماماً
                  // (Recovery Check) مسح فترة السماح إن وجدت بالخطأ
                  if (teacher.gracePeriodEndTime != null) {
                    FirebaseFirestore.instance
                        .collection('teachers')
                        .doc(teacher.id)
                        .update({'gracePeriodEndTime': FieldValue.delete()});
                  }
                  return const Homescreen();
                }

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

                // ثالثاً: حصلت مشكلة (وقت أو عدد) والخانة لسه null -> نبدأ الـ 3 أيام
                // (Initialization Check) نتحقق من عمر الحساب لتجنب مشكلة الـ Race Condition
                final accountAge = now.difference(teacher.createdAt);
                if (accountAge.inMinutes < 5) {
                  // الحساب قيد الإنشاء في الخلفية، لا نكتب فترة سماح
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }

                DateTime newGraceEnd = now.add(const Duration(days: 3));

                // تحديث الداتابيز
                FirebaseFirestore.instance
                    .collection('teachers')
                    .doc(teacher.id)
                    .update({
                  'gracePeriodEndTime': newGraceEnd.toIso8601String(),
                });

                return GracePeriodAlertScreen(graceEndDate: newGraceEnd);
              },
            );
          },
        );
      },
    );
  }
}