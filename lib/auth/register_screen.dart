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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      AppSnackBars.showError(context, "برجاء ملء جميع البيانات الأساسية");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().registerTeacher(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text("إنشاء حساب مدرس",
            style: AppTextStyles.customText(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        backgroundColor: AppColors.primaryMain,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // اللوجو في صفحة التسجيل بشكل مصغر
            Hero(
              tag: 'app_logo',
              child: Image.asset("assets/images/logo.png", height: 100),
            ),
            const SizedBox(height: 30),

            _buildTextField(
                controller: _nameController,
                hint: "اسم المدرس الثلاثي",
                icon: Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField(
                controller: _phoneController,
                hint: "رقم هاتف المدرس",
                icon: Icons.phone_android_outlined,
                inputType: TextInputType.phone),
            const SizedBox(height: 15),
            _buildTextField(
                controller: _emailController,
                hint: "البريد الإلكتروني",
                icon: Icons.email_outlined,
                inputType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _passwordController,
              hint: "كلمة المرور",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _isPasswordVisible,
              onToggle: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),

            const SizedBox(height: 40),
            _isLoading
                ? CircularProgressIndicator(color: AppColors.primaryMain)
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      onPressed: _handleRegister,
                      child: Text("إنشاء الحساب",
                          style: AppTextStyles.customText(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
            const SizedBox(height: 20),
            Text(
              "عند ضغطك على إنشاء حساب، أنت توافق على سياسة الخصوصية الخاصة بنا",
              textAlign: TextAlign.center,
              style: AppTextStyles.customText(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      style: AppTextStyles.customText(),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.primaryMain),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              )
            : null,
        hintText: hint,
        hintStyle: AppTextStyles.customText(
            color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryMain, width: 1.5),
        ),
      ),
    );
  }
}
