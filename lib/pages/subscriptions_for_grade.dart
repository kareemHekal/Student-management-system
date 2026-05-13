import 'package:flutter/material.dart';
import 'package:student_management_system/alert_dialogs/add_edit_subscription_for_grade.dart';

import '../cards/subscription_card.dart';
import '../firebase/firebase_functions.dart';
import '../models/grade_subscriptions_model.dart';
import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';

class SubscriptionsForGrade extends StatelessWidget {
  final String gradeName;

  const SubscriptionsForGrade({super.key, required this.gradeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showAddOrEditSubscriptionDialog(context, gradeName);
            },
            icon:
                const Icon(Icons.add, size: 40, color: AppColors.secondaryMain),
          )
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: StreamBuilder<GradeSubscriptionsModel?>(
        stream: FirebaseFunctions.getGradeSubscriptionsStream(gradeName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'لا توجد اشتراكات لهذه المرحلة',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final grade = snapshot.data!;
          final subscriptions = grade.subscriptions;

          if (subscriptions.isEmpty) {
            return Center(
              child: Text(
                'لا توجد اشتراكات بعد',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: subscriptions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final SubscriptionFee sub = subscriptions[index];
              return SubscriptionCard(
                gradeName: gradeName,
                subscriptionFee: sub,
              );
            },
          );
        },
      ),
    );
  }
}
