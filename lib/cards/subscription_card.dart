import 'package:flutter/material.dart';

import '../Alert dialogs/add_edit_subscription_for_grade.dart';
import '../Alert dialogs/delete_subscription.dart';
import '../colors_app.dart';
import '../models/subscription_fee.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionFee subscriptionFee;
  final String gradeName;

  const SubscriptionCard(
      {super.key, required this.subscriptionFee, required this.gradeName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => DeleteSubscriptionDialog(
            gradeName: gradeName,
            subscriptionName: subscriptionFee.subscriptionName,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [app_colors.ligthGreen, app_colors.ligthGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: app_colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Edit icon button
              IconButton(
                icon: Icon(Icons.edit, color: app_colors.green, size: 28),
                onPressed: () {
                  showAddOrEditSubscriptionDialog(context, gradeName,
                      subscriptionFee: subscriptionFee);
                },
              ),
              const SizedBox(width: 8),

              // Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscriptionFee.subscriptionName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: app_colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${subscriptionFee.subscriptionAmount.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        fontSize: 16,
                        color: app_colors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side icon
              const Icon(
                Icons.payments_rounded,
                size: 32,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
