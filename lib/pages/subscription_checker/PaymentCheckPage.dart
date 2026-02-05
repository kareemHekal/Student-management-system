import 'package:flutter/material.dart';

import '../../firebase/firebase_functions.dart';
import '../../home.dart';
import '../../loadingFile/loading_alert/run_with_loading.dart';
import '../../models/Student_model.dart';
import '../../models/student_paid_subscription.dart';
import '../../models/subscription_fee.dart';
import '../../pages/pdf_genrators/payment_checker_pdf_generator.dart';
import '../../theme/colors_app.dart';
import '../../theme/text_style.dart'; // تأكد من المسار الصحيح
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
    setState(() => grades = fetchedGrades);
  }

  Future<void> fetchSubscriptionsForGrade(String grade) async {
    final gradeSubsStream =
        await FirebaseFunctions.getGradeSubscriptionsStream(grade);
    final gradeSubs = await gradeSubsStream.firstWhere((data) => data != null);
    setState(() {
      gradeSubscriptions = gradeSubs?.subscriptions ?? [];
      selectedSubscription = null;
    });
  }

  Future<void> checkPayments() async {
    if (selectedGrade == null || selectedSubscription == null) {
      // استخدم التنبيه الخاص بك هنا
      return;
    }

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
      if ((paidSub?.paidAmount ?? 0) >=
          selectedSubscription!.subscriptionAmount) {
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
      backgroundColor: const Color(0xffF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryMain,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
        centerTitle: true,
        title: Image.asset("assets/images/logo.png", height: 70),
        toolbarHeight: 100,
        leading: IconButton(
          onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Homescreen()),
              (r) => false),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primaryMain.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  _buildModernDropdown(
                    label: "المرحلة الدراسية",
                    hint: "اختر المرحلة",
                    items: grades,
                    selectedValue: selectedGrade,
                    onChanged: (val) {
                      fetchSubscriptionsForGrade(val);
                      setState(() => selectedGrade = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (gradeSubscriptions.isNotEmpty)
                    _buildModernDropdown(
                      label: "نوع الاشتراك",
                      hint: "اختر الاشتراك",
                      items: gradeSubscriptions
                          .map((s) => s.subscriptionName)
                          .toList(),
                      selectedValue: selectedSubscription?.subscriptionName,
                      onChanged: (val) => setState(() => selectedSubscription =
                          gradeSubscriptions
                              .firstWhere((s) => s.subscriptionName == val)),
                    ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      runWithLoading(
                        context,
                        () async {
                          await checkPayments();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text("بحث وعرض النتائج",
                        style: AppTextStyles.customText(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (startSearch) ...[
              _buildSummaryCard(
                  "الطلاب الذين أتموا الدفع",
                  paidStudents.length,
                  AppColors.statusPresent,
                  Icons.verified_user_rounded,
                  () => _goDetails(context, "قائمة المكملين", paidStudents,
                      AppColors.statusPresent)),
              const SizedBox(height: 15),
              _buildSummaryCard(
                  "طلاب متبقي عليهم مبالغ",
                  unpaidStudents.length,
                  AppColors.statusAbsent,
                  Icons.pending_actions_rounded,
                  () => _goDetails(context, "قائمة المتأخرين", unpaidStudents,
                      AppColors.statusAbsent)),
            ]
          ],
        ),
      ),
    );
  }

  void _goDetails(BuildContext context, String title, List<Studentmodel> list,
      Color color) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => StudentResultListPage(
                  title: title,
                  students: list,
                  grade: selectedGrade!,
                  themeColor: color,
                  onPdfPressed: () async {
                    await runWithLoading(context, () async {
                      generatePdf(
                          title: title,
                          selectedGrade: selectedGrade!,
                          selectedSubscription: selectedSubscription,
                          students: list);
                    });
                  },
                )));
  }

  Widget _buildModernDropdown(
      {required String label,
      required String hint,
      required List<String> items,
      String? selectedValue,
      required Function(String) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTextStyles.customText(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: const Color(0xffF3F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryMain.withOpacity(0.1))),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          hint: Text(hint,
              style:
                  AppTextStyles.customText(fontSize: 14, color: Colors.grey)),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: AppTextStyles.customText(fontSize: 15))))
              .toList(),
          onChanged: (value) => onChanged(value!),
        )),
      ),
    ]);
  }

  Widget _buildSummaryCard(
      String title, int count, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 15),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: AppTextStyles.customText(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("$count طالب",
                      style: AppTextStyles.customText(
                          fontSize: 13, color: AppColors.textSecondary)),
                ])),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color.withOpacity(0.5)),
          ]),
        ));
  }
}