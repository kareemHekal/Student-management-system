import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../home.dart';
import '../models/Studentmodel.dart';
import '../models/student_paid_subscription.dart';
import '../models/subscription_fee.dart';

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

  Future<void> generatePdf(List<Studentmodel> students, String title) async {
    final pdf = pw.Document();
    final arabicFont =
        pw.Font.ttf(await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf'));

    // ✅ Calculate total income
    double totalIncome = 0;
    for (final student in students) {
      final paidSub = student.studentPaidSubscriptions?.firstWhere(
        (s) => s.subscriptionId == selectedSubscription!.id,
        orElse: () => StudentPaidSubscriptions(
          description: '',
          subscriptionId: selectedSubscription!.id,
          paidAmount: 0,
        ),
      );
      totalIncome += paidSub?.paidAmount ?? 0;
    }

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text("المرحلة: ${selectedGrade ?? 'غير محدد'}",
              style: pw.TextStyle(font: arabicFont)),
          pw.Text(
              "الاشتراك: ${selectedSubscription?.subscriptionName ?? 'غير محدد'}",
              style: pw.TextStyle(font: arabicFont)),
          pw.SizedBox(height: 10),

          // ✅ Show total income at the top
          pw.Text(
            "إجمالي المبالغ المدفوعة: ${totalIncome.toStringAsFixed(2)} جنيه",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
              font: arabicFont,
            ),
          ),

          pw.SizedBox(height: 15),

          pw.TableHelper.fromTextArray(
            headers: [
              'المبلغ المتبقي',
              'المبلغ المطلوب',
              'المبلغ المدفوع',
              'رقم الطالب',
              'اسم الطالب'
            ],
            data: students.map((student) {
              final paidSub = student.studentPaidSubscriptions?.firstWhere(
                (s) => s.subscriptionId == selectedSubscription!.id,
                orElse: () => StudentPaidSubscriptions(
                  description: '',
                  subscriptionId: selectedSubscription!.id,
                  paidAmount: 0,
                ),
              );

              final paidAmount = paidSub?.paidAmount ?? 0;
              final totalDue = selectedSubscription!.subscriptionAmount;
              final remaining = totalDue - paidAmount;

              return [
                remaining.toStringAsFixed(2),
                totalDue.toStringAsFixed(2),
                paidAmount.toStringAsFixed(2),
                student.phoneNumber ?? '---',
                student.name ?? '---',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            cellStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
            cellAlignment: pw.Alignment.centerRight,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset(
          "assets/images/2....2.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 180,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
              "المرحلة",
              "اختر المرحلة",
              grades,
              selectedGrade,
              (value) {
                fetchSubscriptionsForGrade(value);
                setState(() {
                  selectedGrade = value;
                });
              },
            ),
            const SizedBox(height: 20),
            if (gradeSubscriptions.isNotEmpty)
              _buildDropdown(
                "الاشتراك",
                "اختر الاشتراك",
                gradeSubscriptions.map((s) => s.subscriptionName).toList(),
                selectedSubscription?.subscriptionName,
                (value) {
                  setState(() {
                    selectedSubscription = gradeSubscriptions
                        .firstWhere((s) => s.subscriptionName == value);
                  });
                },
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: checkPayments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                ),
                child: const Text(
                  "بحث",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (paidStudents.isNotEmpty || unpaidStudents.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => generatePdf(
                              paidStudents, "الطلاب اللي خلّصوا الدفع"),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("PDF للمدفوعين",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => generatePdf(
                              unpaidStudents, "الطلاب اللي لسه مكمّلوش الدفع"),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("PDF لغير المدفوعين",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildStudentList("الطلاب اللي خلّصوا الدفع",
                              paidStudents, Colors.green),
                          const SizedBox(height: 20),
                          _buildStudentList("الطلاب اللي لسه مكمّلوش الدفع",
                              unpaidStudents, Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (startSearch)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text("لا يوجد طلاب في هذه المرحلة")),
              ),
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
            border: Border.all(color: app_colors.darkGrey, width: 2),
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
                      style: const TextStyle(color: app_colors.darkGrey)),
                );
              }).toList(),
              onChanged: (value) => onChanged(value!),
              icon:
                  const Icon(Icons.arrow_drop_down, color: app_colors.darkGrey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(
      String title, List<Studentmodel> students, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 10),
        ...students.map((student) => Card(
              child: ListTile(
                title: Text(student.name ?? "غير معروف"),
                subtitle: Text(student.phoneNumber ?? "لا يوجد رقم"),
              ),
            )),
      ],
    );
  }
}
