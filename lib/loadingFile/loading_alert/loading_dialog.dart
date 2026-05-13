import 'package:flutter/material.dart';
import 'package:student_management_system/theme/colors_app.dart';
import 'package:student_management_system/theme/text_style.dart';

class LoadingDialog extends StatelessWidget {
  final String? text;

  const LoadingDialog({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        // إزالة أي خلفية أو حدود افتراضية للديالوج
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            // حاوية صغيرة جداً وبسيطة
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryMain, // لون الهوية الأساسي
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // ليأخذ الصندوق حجم المحتوى فقط
              children: [
                // مؤشر تحميل بسيط وبلون فاتح (أبيض)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.secondaryMain),
                  ),
                ),
                const SizedBox(width: 20),
                // نص بسيط وواضح
                Flexible(
                  child: Text(
                    text ?? 'جاري التحميل...',
                    style: AppTextStyles.customText(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}