
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
import 'bloc/observer.dart';
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

  // Check for internet connectivity
  var connectivityResult = await (Connectivity().checkConnectivity());
  bool hasConnection = (connectivityResult != ConnectivityResult.none);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: MyApp(hasConnection: hasConnection),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasConnection;
  const MyApp({super.key, required this.hasConnection});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(/* التيم بتاعك */),
      // لو مفيش نت يروح لصفحة النت، لو فيه نت يشوف حالة التسجيل
      home: !hasConnection ? NoConnectionPage() : AuthGate(),
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // حالة 1: المدرس مش مسجل دخول أصلاً
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // حالة 2: المدرس مسجل دخول، بنجيب بياناته ونشوف اشتراكه
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('teachers')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, teacherSnapshot) {
            if (teacherSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
              Teacher teacher = Teacher.fromJson(
                  teacherSnapshot.data!.data() as Map<String, dynamic>,
                  teacherSnapshot.data!.id);

              // حفظ البيانات في الـ Provider عشان نستخدمها في أي مكان
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<TeacherProvider>(context, listen: false)
                    .setTeacher(teacher);
              });

              // التوجيه بناءً على حالة الاشتراك
              if (teacher.hasActiveSubscription) {
                return const Homescreen();
              } else {
                return SubscriptionExpiredScreen();
              }
            }

            // لو حصل مشكلة أو الدوك مش موجود
            return LoginScreen();
          },
        );
      },
    );
  }
}