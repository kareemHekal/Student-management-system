import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:student_management_system/loadingFile/loading_alert/run_with_loading.dart';
import 'package:student_management_system/pages/pdf_genrators/payment_checker_pdf_generator.dart';

import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../models/Studentmodel.dart';
import '../../models/student_paid_subscription.dart';
import '../../models/subscription_fee.dart';
import '../../theme/colors_app.dart';
import 'students_subscription_cheker_list.dart';

class PaymentCheckPage extends StatefulWidget {
  const PaymentCheckPage({super.key});

  @override
  State<PaymentCheckPage> createState() => _PaymentCheckPageState();
}

class _PaymentCheckPageState extends State<PaymentCheckPage> {
  List<String> grades = [];
  String? selectedGrade;
  SubscriptionFee? selectedSubscription;
  List<SubscriptionFee> gradeSubscriptions = [];

  List<Studentmodel> paidStudents = [];
  List<Studentmodel> unpaidStudents = [];
  bool startSearch = false;

  @override
  void initState() {
    super.initState();
    fetchGrades();
  }

  Future<void> fetchGrades() async {
    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();
    setState(() {
      grades = fetchedGrades;
    });
  }

  Future<void> fetchSubscriptionsForGrade(String grade) async {
    final gradeSubsStream =
        await FirebaseFunctions.getGradeSubscriptionsStream(grade);
    final gradeSubs = await gradeSubsStream.firstWhere((data) => data != null);
    setState(() {
      gradeSubscriptions = gradeSubs?.subscriptions ?? [];
      selectedSubscription = null; // reset when grade changes
    });
  }

  Future<void> checkPayments() async {
    if (selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار المرحلة.")),
      );
      return;
    }
    if (selectedSubscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار الاشتراك.")),
      );
      return;
    }

    // Get all students in the selected grade
    final students =
        await FirebaseFunctions.getAllStudentsByGrade_future(selectedGrade!);

    List<Studentmodel> paid = [];
    List<Studentmodel> unpaid = [];

    for (var student in students) {
      final paidSub = student.studentPaidSubscriptions?.firstWhere(
        (s) => s.subscriptionId == selectedSubscription!.id,
        orElse: () => StudentPaidSubscriptions(
            subscriptionId: '', description: '', paidAmount: 0),
      );

      final paidAmount = paidSub?.paidAmount ?? 0;
      final totalDue = selectedSubscription!.subscriptionAmount;

      if (paidAmount >= totalDue) {
        paid.add(student);
      } else {
        unpaid.add(student);
      }
    }

    setState(() {
      paidStudents = paid;
      unpaidStudents = unpaid;
      startSearch = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homescreen()),
              (route) => false,
            );
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.secondaryMain,
          ),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 100, width: 90),
        toolbarHeight: 150,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown("المرحلة", "اختر المرحلة", grades, selectedGrade,
                (value) {
              fetchSubscriptionsForGrade(value);
              setState(() => selectedGrade = value);
            }),
            const SizedBox(height: 20),
            if (gradeSubscriptions.isNotEmpty)
              _buildDropdown(
                "الاشتراك",
                "اختر الاشتراك",
                gradeSubscriptions.map((s) => s.subscriptionName).toList(),
                selectedSubscription?.subscriptionName,
                (value) {
                  setState(() => selectedSubscription = gradeSubscriptions
                      .firstWhere((s) => s.subscriptionName == value));
                },
              ),
            const SizedBox(height: 30),

            // Search Button
            Center(
              child: ElevatedButton(
                onPressed: checkPayments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryMain,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("بحث وعرض النتائج",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),

            if (startSearch) ...[
              _buildSummaryCard(
                title: "الطلاب الذين أتموا الدفع",
                count: paidStudents.length,
                color: Colors.green,
                icon: Icons.check_circle_rounded,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentResultListPage(
                          title: "قائمة المكملين الدفع",
                          students: paidStudents,
                          grade: selectedGrade!,
                          themeColor: Colors.green,
                          onPdfPressed: () async {
                            await runWithLoading(context, () async {
                              generatePdf(
                                title: "الطلاب الذين أتموا الدفع",
                                selectedGrade: selectedGrade!,
                                selectedSubscription: selectedSubscription,
                                students: paidStudents,
                              );
                            });
                          }),
                    )),
              ),
              const SizedBox(height: 15),
              // --- Summary Card for Unpaid Students ---
              _buildSummaryCard(
                title: "طلاب متبقي عليهم مبالغ",
                count: unpaidStudents.length,
                color: Colors.red,
                icon: Icons.warning_rounded,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentResultListPage(
                          title: "قائمة غير المكملين الدفع",
                          students: unpaidStudents,
                          grade: selectedGrade!,
                          themeColor: Colors.red,
                          onPdfPressed: () async {
                            await runWithLoading(context, () async {
                              generatePdf(
                                title: "الطلاب الذين لم يتموا الدفع",
                                selectedGrade: selectedGrade!,
                                selectedSubscription: selectedSubscription,
                                students: unpaidStudents,
                              );
                            });
                          }),
                    )),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      {required String title,
      required int count,
      required Color color,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 25,
                child: Icon(icon, color: color, size: 30)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("$count طالب متواجد",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryMain, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: selectedValue,
              isExpanded: true,
              hint: Text(hint, style: TextStyle(color: Colors.grey[700])),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(color: AppColors.primaryMain)),
                );
              }).toList(),
              onChanged: (value) => onChanged(value!),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.primaryMain),
            ),
          ),
        ),
      ],
    );
  }
}
