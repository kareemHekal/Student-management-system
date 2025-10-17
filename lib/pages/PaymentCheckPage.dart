import 'package:fatma_elorbany/models/Studentmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../home.dart';

class PaymentCheckPage extends StatefulWidget {
  const PaymentCheckPage({super.key});

  @override
  State<PaymentCheckPage> createState() => _PaymentCheckPageState();
}

class _PaymentCheckPageState extends State<PaymentCheckPage> {
  late List<String> secondaries = [];
  List<String> categories = [
    "First Month",
    "Second Month",
    "Third Month",
    "Fourth Month",
    "Fifth Month",
    "Explaining Note",
    "Review Note"
  ];

  String? selectedSecondary;
  String? selectedCategory;
  List<Studentmodel> paidStudents = [];
  List<Studentmodel> unpaidStudents = [];
  bool startSearch=false;

  Future<void> fetchGrades() async {
    List<String> fetchedGrades = await FirebaseFunctions.getGradesList();
    setState(() {
      secondaries = fetchedGrades;
    });
  }

  Future<void> checkPayments() async {
    if (selectedSecondary == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both grade and category.")),
      );
      return;
    }
    print(selectedSecondary);
    print(selectedCategory);
    List<Studentmodel> students =
    await FirebaseFunctions.getAllStudentsByGrade_future(selectedSecondary!);

    List<Studentmodel> paid = [];
    List<Studentmodel> unpaid = [];
    if (selectedCategory=="First Month"){
      for (var student in students) {
        if (student.firstMonth == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    }else if (selectedCategory=="Second Month"){
      for (var student in students) {
        if (student.secondMonth == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    }else if (selectedCategory=="Third Month"){
      for (var student in students) {
        if (student.thirdMonth == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    } else if (selectedCategory=="Fourth Month"){
      for (var student in students) {
        if (student.fourthMonth == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    }else if (selectedCategory=="Fifth Month"){
      for (var student in students) {
        if (student.fifthMonth == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    } else if (selectedCategory=="Explaining Note"){
      for (var student in students) {
        if (student.explainingNote == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    } else if (selectedCategory=="Review Note"){
      for (var student in students) {
        if (student.reviewNote == true) {
          paid.add(student);
        } else {
          unpaid.add(student);
        }
      }
    }

    setState(() {
      paidStudents = paid;
      unpaidStudents = unpaid;
      startSearch=true;
    });
    print('Paid Students: ${paidStudents.length}');
    print('Unpaid Students: ${unpaidStudents.length}');

  }

  @override
  void initState() {
    super.initState();
    fetchGrades();
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
              MaterialPageRoute(
                builder: (context) => const Homescreen(),
              ),
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
            _buildDropdown("G R A D E", "Select a grade", secondaries,
                selectedSecondary, (value) => selectSecondary(value)),
            const SizedBox(height: 15),
            _buildDropdown("Select Month", "Select the month", categories,
                selectedCategory, (value) => selectCategory(value)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: checkPayments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: app_colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                          onPressed: () => generatePdf(paidStudents, "Paid Students"),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("PDF Paid",style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => generatePdf(unpaidStudents, "Unpaid Students"),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("PDF Unpaid",style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),

                    Expanded(
                      child: ListView(
                        children: [
                          _buildStudentList("Paid Students", paidStudents, Colors.green),
                          const SizedBox(height: 20),
                          _buildStudentList("Unpaid Students", unpaidStudents, Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (startSearch)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text("You don't have students in this grade")),
              ),
          ],
        ),
      ),

    );
  }

  Widget _buildStudentList(String title, List<Studentmodel> students, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 10),
        ...students.map((student) => Card(
          child: ListTile(
            title: Text(student.name ?? "Unknown"),
            subtitle: Text(student.phoneNumber ?? "No Phone"),
          ),
        )),
      ],
    );
  }

  void selectSecondary(String secondary) {
    setState(() {
      selectedSecondary = secondary;
    });
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  Future<void> generatePdf(List<Studentmodel> students, String title) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('fonts/NotoKufiArabic-Regular.ttf'),
    );

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl, // <<< دا مهم جداً
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            "المرحلة: ${selectedSecondary ?? 'غير محدد'}",
            style: pw.TextStyle(fontSize: 14, font: arabicFont),
          ),
          pw.Text(
            "الشهر: ${selectedCategory ?? 'غير محدد'}",
            style: pw.TextStyle(fontSize: 14, font: arabicFont),
          ),
          pw.Text(
            "عدد الطلاب: ${students.length}",
            style: pw.TextStyle(fontSize: 14, font: arabicFont),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['رقم الهاتف', 'الاسم'],
            // عكس الترتيب
            data: students.map((student) => [
                      student.phoneNumber ?? 'لا يوجد',
                      student.name ?? 'غير معروف',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            cellStyle: pw.TextStyle(font: arabicFont),
            cellAlignment: pw.Alignment.centerRight,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildDropdown(String label, String hint, List<String> items,
      String? selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    child: Text(item, style: const TextStyle(color: app_colors.darkGrey)));
              }).toList(),
              onChanged: (value) => onChanged(value!),
              icon: const Icon(Icons.arrow_drop_down, color: app_colors.darkGrey),
            ),
          ),
        ),
      ],
    );
  }
}