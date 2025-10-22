import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../colors_app.dart';

class ForgetPasswordPage extends StatefulWidget {
  ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _emailController = TextEditingController();
  bool _passwordResetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future passwordReset(context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("تم بنجاح"),
          content: Text(
            "تم إرسال رابط إعادة تعيين كلمة المرور بنجاح! تحقق من بريدك الإلكتروني.",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("حسناً"),
            ),
          ],
        ),
      );
      setState(() {
        _passwordResetSent = true;
      });
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("خطأ"),
          content: Text(
            e.message.toString(),
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("حسناً"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: app_colors.green),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/125.png",
                    width: 300,
                    height: 400,
                  ),
                ],
              ),
              Text(
                textAlign: TextAlign.center,
                "فقط أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.",
                style: TextStyle(color: app_colors.darkGrey),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: TextFormField(
                  obscureText: _passwordResetSent,
                  cursorColor: app_colors.green,
                  style: TextStyle(color: Colors.black, fontSize: 20),
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "البريد الإلكتروني",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: app_colors.green.withOpacity(0.1),
                    filled: true,
                    prefixIcon:
                        const Icon(Icons.email, color: app_colors.green),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'من فضلك أدخل البريد الإلكتروني';
                    } else if (!value.contains('@') || !value.contains('.')) {
                      return 'عنوان البريد الإلكتروني غير صالح';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  passwordReset(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: app_colors.darkGrey,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                  child: const Text(
                    "إرسال",
                    style: TextStyle(fontSize: 18, color: app_colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
