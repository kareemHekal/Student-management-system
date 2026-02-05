import 'package:flutter/material.dart';
import 'package:student_management_system/firebase/auth_services.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/snack_bar.dart';
import 'package:student_management_system/theme/text_style.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // 1. التحقق من أن الحقول ليست فارغة
    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      AppSnackBars.showError(context, "برجاء ملء جميع البيانات");
      return;
    }

    // 2. التحقق من الاسم (على الأقل اسمين)
    if (name.split(' ').length < 2) {
      AppSnackBars.showError(context, "برجاء كتابة الاسم ثنائي على الأقل");
      return;
    }

    // 3. التحقق من رقم الهاتف (11 رقم ويبدأ بـ 01)
    final phoneRegex = RegExp(r'^01[0125][0-9]{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      AppSnackBars.showError(
          context, "رقم الهاتف غير صحيح (يجب أن يكون 11 رقم)");
      return;
    }

    // 4. التحقق من البريد الإلكتروني (ابن ناس)
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      AppSnackBars.showError(context, "صيغة البريد الإلكتروني غير صحيحة");
      return;
    }

    // 5. التحقق من كلمة المرور (6 أرقام أو حروف على الأقل)
    if (password.length < 6) {
      AppSnackBars.showError(
          context, "كلمة المرور ضعيفة (يجب ألا تقل عن 6 رموز)");
      return;
    }

    // لو كله تمام، ابدأ عملية التسجيل
    setState(() => _isLoading = true);
    try {
      await AuthService().registerTeacher(email, password, name, phone);
      if (!mounted) return;
      AppSnackBars.showSuccess(
          context, "تم إنشاء الحساب بنجاح! تواصل مع الإدارة لتفعيله.");
      Navigator.pop(context);
    } catch (e) {
      AppSnackBars.showError(context, "حدث خطأ: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1. تعريف الـ FocusNodes للتنقل بين الخانات
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // بنجيب عرض الشاشة عشان نظبط مقاسات الهيدر
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // اللون اللي اخترناه (أبيض مخضر خفيف)
      backgroundColor: const Color(0xFFEBFFF4),
      body: SingleChildScrollView(
        // دي أهم حركة عشان الكيبورد ترفع التصميم
        child: Column(
          children: [
            // 1. الهيدر العلوي (الجزء الملون)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primaryMain,
                    AppColors.primaryMain.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(50), // انحناء احترافي
                ),
              ),
              child: Column(
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset("assets/images/logo.png", height: 70),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "إنشاء حساب جديد",
                    style: AppTextStyles.customText(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "سجل بياناتك للبدء في إدارة غيابك",
                    style: AppTextStyles.customText(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 2. كارت البيانات (الذي يحتوي على الـ Fields)
            // بنعمل تداخل بسيط (Negative Margin) عشان الكارت يطلع فوق الهيدر شوية
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        nextFocus: _phoneFocus,
                        hint: "اسم المدرس الثلاثي",
                        icon: Icons.person_rounded,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        nextFocus: _emailFocus,
                        hint: "رقم الهاتف",
                        icon: Icons.phone_android_rounded,
                        inputType: TextInputType.phone,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        nextFocus: _passwordFocus,
                        hint: "البريد الإلكتروني",
                        icon: Icons.alternate_email_rounded,
                        inputType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        hint: "كلمة المرور",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        action: TextInputAction.done,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.primaryMain)
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryMain,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _handleRegister,
                                child: Text(
                                  "إنشاء الحساب",
                                  style: AppTextStyles.customText(
                                    color: Colors.white,
                              fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. زر العودة
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  text: "لديك حساب بالفعل؟ ",
                  style: AppTextStyles.customText(
                      color: Colors.grey[600]!, fontSize: 14),
                  children: [
                    TextSpan(
                      text: "سجل دخولك",
                      style: AppTextStyles.customText(
                        color: AppColors.primaryMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // مساحة أمان في الآخر
          ],
        ),
      ),
    );
  }

  // التعديل في الـ TextField عشان يدعم الـ Focus والـ Next
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    required IconData icon,
    required TextInputAction action,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: action,
      // دي الحركة اللي بتنقل للخانة اللي بعدها برمجياً
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          _handleRegister(); // لو في آخر خانة وداس Done يبدأ يسجل
        }
      },
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryMain),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: onToggle,
              )
            : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
