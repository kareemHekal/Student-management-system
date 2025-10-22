import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/firebase_functions.dart';
import '../provider.dart';
import '../colors_app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    var dataprovider = Provider.of<DataProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              const SizedBox(height: 50),
              _inputField(context, dataprovider),
              const SizedBox(height: 30),
              _forgotPassword(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNavigationBar(context),
    );
  }

  _header(context) {
    return Column(
      children: [
        Image.asset(
          "assets/images/2....2.png",
          height: 100,
          width: 90,
        ),
        const SizedBox(height: 20),
        const Text(
          "مرحباً بعودتك",
          style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.bold, color: app_colors.green),
        ),
        const Text("أدخل بياناتك لتسجيل الدخول",
            style: TextStyle(color: app_colors.darkGrey)),
      ],
    );
  }

  _inputField(context, DataProvider dataprovider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          cursorColor: app_colors.green,
          style: const TextStyle(color: Colors.black, fontSize: 20),
          controller: _emailController,
          decoration: InputDecoration(
              hintText: "البريد الإلكتروني",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: app_colors.green.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email, color: app_colors.green)),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'من فضلك أدخل البريد الإلكتروني';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          cursorColor: app_colors.green,
          style: const TextStyle(color: Colors.black, fontSize: 20),
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: "كلمة المرور",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: app_colors.green.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password, color: app_colors.green),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
            return null;
          },
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            FirebaseFunctions.login(
              onEror: (message) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("خطأ"),
                    content: Text(
                      message,
                      style: const TextStyle(color: Colors.black),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("حسناً"),
                      ),
                    ],
                  ),
                );
              },
              onSucsses: () {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null && !user.emailVerified) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("تأكيد البريد الإلكتروني"),
                      content: const Text(
                        "بريدك الإلكتروني غير مفعل. يرجى تفعيله قبل المتابعة.",
                        style: TextStyle(color: Colors.black),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () async {
                            await user.sendEmailVerification();
                            Navigator.pop(context);
                          },
                          child: const Text("إرسال رسالة التفعيل"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("إلغاء"),
                        ),
                      ],
                    ),
                  );
                }
                dataprovider.initUser;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/HomeScreen',
                      (Route<dynamic> route) => false,
                );
              },
              _emailController.text.trim(),
              _passwordController.text,
              Username: '',
            );
            if (_formKey.currentState!.validate()) {
              print('Email: ${_emailController.text}');
              print('Password: ${_passwordController.text}');
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: app_colors.darkGrey,
          ),
          child: const Text(
            "تسجيل الدخول",
            style: TextStyle(fontSize: 20, color: app_colors.green),
          ),
        ),
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/Forgetpasswordpage');
      },
      child: const Text(
        "هل نسيت كلمة المرور؟",
        style: TextStyle(color: app_colors.green),
      ),
    );
  }

  _bottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: app_colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("ليس لديك حساب؟ ",
              style: TextStyle(color: Colors.blueGrey)),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/SignupPage');
            },
            child: const Text(
              "إنشاء حساب",
              style: TextStyle(color: app_colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
