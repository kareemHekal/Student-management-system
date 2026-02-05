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