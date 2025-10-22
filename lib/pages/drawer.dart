import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Alert dialogs/Delete diaolog.dart';
import '../Alert dialogs/ResetAbscenceMonthDialog.dart';
import '../Alert dialogs/change_password.dart';
import '../Alert dialogs/verifiy_password.dart';
import '../colors_app.dart';
import '../constants.dart';
import '../firebase/firebase_functions.dart';
import '../models/Big invoice.dart';
import '../models/payment.dart';
import 'PaymentCheckPage.dart';
import 'allgrades.dart';
import 'invoices page.dart';

class CustomDrawer extends StatefulWidget {
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  void getCurrentDate() {
    DateTime now = DateTime.now();
    date = now.toIso8601String().substring(0, 10); // yyyy-mm-dd
    Day = now.weekday == 1
        ? 'Monday'
        : now.weekday == 2
            ? 'Tuesday'
            : now.weekday == 3
                ? 'Wednesday'
                : now.weekday == 4
                    ? 'Thursday'
                    : now.weekday == 5
                        ? 'Friday'
                        : now.weekday == 6
                            ? 'Saturday'
                            : 'Sunday';
  }

  late double totalAmount;
  late String description;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController totalAmountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late String? date;
  late String? Day;
  bool isDangresAreaOpen = false;
  List<String> tags = [];
  List<String>? fetchedGrades;
  List<String> options = ['Absence', 'bills'];

  @override
  void initState() {
    super.initState();
    getCurrentDate();
    fetchGrades();
  }

  Future<void> fetchGrades() async {
    fetchedGrades = await FirebaseFunctions.getGradesList();
    options.addAll(fetchedGrades ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // الجزء الأول: الصورة والاسم
          Container(
            decoration: const BoxDecoration(
              color: app_colors.darkGrey,
            ),
            width: double.infinity,
            height: 220,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    "assets/images/1......1.png",
                    height: 120,
                    width: 120,
                  ),
                  Text(
                    Constants.teacherName,
                    style: GoogleFonts.qwitcherGrypen(
                        color: app_colors.ligthGreen, fontSize: 50),
                  ),
                ],
              ),
            ),
          ),

          // الجزء الثاني: الخيارات
          Expanded(
            child: Container(
              color: app_colors.ligthGreen,
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/StudentsTab', (route) => false);
                    },
                    child: ListTile(
                      leading:
                          Image.asset("assets/images/students.png", width: 40),
                      title: const Text(
                        "كل الطلاب",
                        style: TextStyle(color: app_colors.green, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => StartNewMonthDialog(),
                      );
                    },
                    child: ListTile(
                      leading:
                          Image.asset("assets/images/restart.png", width: 40),
                      title: const Text(
                        "إعادة ضبط الغياب",
                        style: TextStyle(color: app_colors.green, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Invoicespage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: ListTile(
                      leading:
                          Image.asset("assets/images/invoice.png", width: 40),
                      title: const Text(
                        "عرض جميع الفواتير",
                        style: TextStyle(color: app_colors.green, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("إضافة مصروف جديد"),
                            content: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: totalAmountController,
                                    decoration: const InputDecoration(
                                      labelText: "المبلغ الإجمالي",
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'الرجاء إدخال المبلغ';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextField(
                                    controller: descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: "الوصف",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  FirebaseFirestore firestore =
                                      FirebaseFirestore.instance;
                                  DocumentSnapshot docSnapshot = await firestore
                                      .collection('big_invoices')
                                      .doc(date)
                                      .get();

                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    totalAmount = double.tryParse(
                                            totalAmountController.text) ??
                                        0.0;
                                    description = descriptionController.text;

                                    Payment newPayment = Payment(
                                      amount: totalAmount,
                                      description: description,
                                      dateTime: DateTime.now(),
                                    );

                                    if (docSnapshot.exists) {
                                      Map<String, dynamic> data = docSnapshot
                                          .data() as Map<String, dynamic>;

                                      BigInvoice bigInvoice =
                                          BigInvoice.fromJson(data);

                                      bigInvoice.payments.add(newPayment);

                                      await firestore
                                          .collection('big_invoices')
                                          .doc(date)
                                          .update(bigInvoice.toJson());
                                    } else {
                                      BigInvoice bigInvoice = BigInvoice(
                                        date: date ?? "",
                                        day: Day ?? "",
                                        invoices: [],
                                        payments: [newPayment],
                                      );

                                      await firestore
                                          .collection('big_invoices')
                                          .doc(date)
                                          .set(bigInvoice.toJson());
                                    }

                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/HomeScreen',
                                      (route) => false,
                                    );
                                  } else {
                                    return;
                                  }
                                },
                                child: const Text('حفظ'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: ListTile(
                      leading:
                          Image.asset("assets/images/clipboard.png", width: 40),
                      title: const Text(
                        "إضافة مصروف",
                        style: TextStyle(color: app_colors.green, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Allgrades()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: ListTile(
                      leading: Image.asset("assets/images/edit-table.png", width: 40),
                      title: const Text(
                        "مراحل الدراسة",
                        style: TextStyle(color: app_colors.green, fontSize: 15),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PaymentCheckPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: ListTile(
                      leading: Image.asset("assets/images/seo.png", width: 40),
                      title: const Text(
                        "مراجعة المدفوعات",
                        style: TextStyle(color: app_colors.green, fontSize: 15),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showVerifyPasswordDialog(
                        context: context,
                        onVerified: () {
                          showChangePasswordDialog(context);
                        },
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text(
                        "تغيير كلمة المرور",
                        style:
                        TextStyle(color: app_colors.green, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // الجزء الثالث: منطقة الخطر
          GestureDetector(
            onTap: () {
              isDangresAreaOpen = !isDangresAreaOpen;
              setState(() {});
            },
            child: Container(
              decoration: const BoxDecoration(
                color: app_colors.darkGrey,
              ),
              width: double.maxFinite,
              height: 60,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      isDangresAreaOpen == false
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.keyboard_double_arrow_down_rounded,
                      color: app_colors.green,
                    ),
                    const Spacer(),
                    const Text(
                      "منطقة الخطر",
                      style: TextStyle(color: app_colors.green, fontSize: 20),
                    )
                  ],
                ),
              ),
            ),
          ),
          Container(
              color: app_colors.darkGrey,
              child: isDangresAreaOpen == true
                  ? Column(
                      children: [
                        const Divider(
                          endIndent: 15,
                          indent: 15,
                          color: Colors.red,
                          thickness: 2,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text("تسجيل الخروج",
                                  style: TextStyle(
                                      color: app_colors.green, fontSize: 20)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffFF0000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout,
                                        color: Colors.white, size: 30),
                                    SizedBox(width: 15),
                                    Text(
                                      "تسجيل الخروج",
                                      style: TextStyle(
                                          color: app_colors.white,
                                          fontSize: 18),
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  FirebaseAuth.instance.signOut();
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/LoginPage', (route) => false);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          endIndent: 8,
                          indent: 8,
                          color: Colors.red,
                          thickness: 2,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text("حذف كل البيانات",
                                  style: TextStyle(
                                      color: app_colors.green, fontSize: 20)),
                            ),
                            ChipsChoice<String>.multiple(
                              value: tags,
                              onChanged: (val) {
                                setState(() {
                                  tags = val;
                                });
                              },
                              choiceItems: C2Choice.listFrom<String, String>(
                                source: options,
                                value: (i, v) =>
                                    "$v-$i", // اضف index لتفادي التكرار
                                label: (i, v) => v,
                              ),
                              choiceStyle: C2ChipStyle.outlined(
                                borderWidth: 2,
                                backgroundColor: app_colors.green,
                                selectedStyle: const C2ChipStyle(
                                  borderColor: Colors.redAccent,
                                  foregroundColor: Colors.redAccent,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffFF0000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_sweep_rounded,
                                        color: Colors.white, size: 30),
                                    SizedBox(width: 15),
                                    Text(
                                      "حذف البيانات المختارة",
                                      style: TextStyle(
                                          color: app_colors.white,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return CustomConfirmDialog(
                                        title: "هل أنت متأكد؟",
                                        content:
                                            "سيتم حذف البيانات التي اخترتها. هل أنت متأكد؟",
                                        tags: tags,
                                        onConfirm: (tags) async {
                                          for (var tag in tags) {
                                            if (fetchedGrades!.contains(tag)) {
                                              await FirebaseFunctions
                                                  .deleteCollection(tag);
                                            } else if (tag == 'bills') {
                                              FirebaseFunctions
                                                  .deleteBigInvoiceCollection();
                                            } else {
                                              List<String> allDaysOfWeek = [
                                                "Monday",
                                                "Tuesday",
                                                "Wednesday",
                                                "Thursday",
                                                "Friday",
                                                "Saturday",
                                                "Sunday"
                                              ];
                                              for (var day in allDaysOfWeek) {
                                                await FirebaseFunctions
                                                    .deleteAbsencesSubcollection(
                                                        day);
                                              }
                                            }
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : null),
        ],
      ),
    );
  }
}
