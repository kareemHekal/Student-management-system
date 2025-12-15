import 'package:flutter/material.dart';

import '../Alert dialogs/add_edit_subscription_for_grade.dart';
import '../Alert dialogs/delete_subscription.dart';
import '../models/subscription_fee.dart';
import '../theme/colors_app.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionFee subscriptionFee;
  final String gradeName;

  const SubscriptionCard(
      {super.key, required this.subscriptionFee, required this.gradeName});

  // Helper method for the decorative background circles
  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  // Helper method for the icon buttons inside circles (No functional change)
  Widget _buildActionCircle({
    required IconData icon,
    required Color circleColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryMain,
                  AppColors.secondaryMain,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ===== Decorative Circles (ADJUSTED PLACEMENT) =====
                Positioned(
                  // *** ADJUSTED POSITIONING FOR CURVE FIT ***
                  // Pushing the center of the circle further into the corner.
                  top: -10, // Increased offset towards the top edge
                  right: -10, // Increased offset towards the right edge
                  child: _buildCircle(
                      60, 0.1), // Slightly increased size (from 50 to 60)
                ),
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: _buildCircle(100, 0.15),
                ),

                // ===== Card Content =====
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Payments Icon (I'll keep this white for better contrast with the gradient)
                      const Icon(
                        Icons.payments_rounded,
                        size: 38,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 16),

                      // Text section (Subscription Name and Amount)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscriptionFee.subscriptionName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              // Using AppColors.white for consistency with AppColors.textOnDark
                              '${subscriptionFee.subscriptionAmount.toStringAsFixed(2)} EGP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- ACTION BUTTONS (Edit and Delete) IN CIRCLES ---
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Edit Icon in Circle
                          _buildActionCircle(
                            icon: Icons.edit,
                            circleColor: AppColors.primaryMain.withOpacity(0.3),
                            iconColor: AppColors.white,
                            onPressed: () {
                              showAddOrEditSubscriptionDialog(
                                context,
                                gradeName,
                                subscriptionFee: subscriptionFee,
                              );
                            },
                          ),
                          // CORRECTED: Added SizedBox for spacing instead of 'spacing: 12'
                          const SizedBox(width: 12),

                          // 2. Delete Icon in Circle
                          _buildActionCircle(
                            icon: Icons.delete_forever,
                            circleColor: AppColors.primaryMain.withOpacity(0.3),
                            iconColor: AppColors.white,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => DeleteSubscriptionDialog(
                                  gradeName: gradeName,
                                  id: subscriptionFee.id,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
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