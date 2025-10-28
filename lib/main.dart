
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/noInternetConnection.dart';
import 'bloc/observer.dart';
import 'colors_app.dart';
import 'firebase/firebase_options.dart';
import 'home.dart';
import 'pages/AllStudentPage.dart';

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
    MyApp(hasConnection: hasConnection),
  );
}

class MyApp extends StatelessWidget {
  final bool hasConnection;

  const MyApp({super.key, required this.hasConnection});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 20, color: app_colors.darkGrey,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        useMaterial3: true,
      ),
      home: hasConnection
          ? const Homescreen()
          : NoConnectionPage(), // Show NoConnectionPage if no internet
      routes: {
        '/HomeScreen': (context) => const Homescreen(),
        '/StudentsTab': (context) => const AllStudentsTab(),
      },
    );
  }
}
