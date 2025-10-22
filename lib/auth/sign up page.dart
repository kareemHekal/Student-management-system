import 'package:flutter/material.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            height: MediaQuery.of(context).size.height - 50,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const SizedBox(height: 60.0),
                    Image.asset(
                      "assets/images/2....2.png",
                      height: 100,
                      width: 90,
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      "__ إنشاء حساب __",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: app_colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "أنشئ حسابك الآن",
                      style: TextStyle(fontSize: 15, color: app_colors.darkGrey),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: "اسم المستخدم",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: app_colors.green.withOpacity(0.1),
                              filled: true,
                              prefixIcon: const Icon(Icons.person,
                                  color: app_colors.green),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'من فضلك أدخل اسم المستخدم';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: "البريد الإلكتروني",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: app_colors.green.withOpacity(0.1),
                              filled: true,
                              prefixIcon: const Icon(Icons.email,
                                  color: app_colors.green),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'من فضلك أدخل البريد الإلكتروني';
                              }
                              if (!value.contains('@')) {
                                return 'أدخل بريدًا إلكترونيًا صحيحًا';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: "كلمة المرور",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: app_colors.green.withOpacity(0.1),
                              filled: true,
                              prefixIcon: const Icon(Icons.password,
                                  color: app_colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: app_colors.green,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'من فضلك أدخل كلمة المرور';
                              }
                              if (value.length < 8) {
                                return 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: "تأكيد كلمة المرور",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: app_colors.green.withOpacity(0.1),
                              filled: true,
                              prefixIcon: const Icon(Icons.password,
                                  color: app_colors.green),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: app_colors.green,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isConfirmPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'من فضلك أدخل تأكيد كلمة المرور';
                              }
                              if (value != _passwordController.text) {
                                return 'كلمتا المرور غير متطابقتين';
                              }
                              return null;
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.only(top: 3, left: 3),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        FirebaseFunctions.createAccount(
                          Username: _usernameController.text,
                          onEror: (message) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("خطأ"),
                                content: Text(
                                  message,
                                  style: TextStyle(color: Colors.black),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("حسنًا"),
                                  ),
                                ],
                              ),
                            );
                          },
                          onSucsses: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("تحقق من بريدك الإلكتروني"),
                                content: Text(
                                  'يرجى التحقق من بريدك الإلكتروني وتأكيد حسابك.',
                                  style: TextStyle(color: Colors.black),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/LoginPage',
                                            (Route<dynamic> route) => false,
                                      );
                                    },
                                    child: Text("الذهاب إلى صفحة تسجيل الدخول"),
                                  ),
                                ],
                              ),
                            );
                          },
                          _emailController.text,
                          _passwordController.text,
                        );
                      }
                    },
                    child: const Text(
                      "إنشاء حساب",
                      style: TextStyle(fontSize: 20, color: app_colors.green),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: app_colors.darkGrey,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("هل لديك حساب بالفعل؟"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/LoginPage');
                      },
                      child: const Text(
                        "تسجيل الدخول",
                        style: TextStyle(color: app_colors.green),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
