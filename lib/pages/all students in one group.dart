import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../cards/StudentWidget.dart';
import '../colors_app.dart';
import '../firebase/firebase_functions.dart';
import '../loadingFile/loadingWidget.dart';
import '../models/Magmo3aModel.dart';
import '../models/Studentmodel.dart';

class StudentInAgroup extends StatefulWidget {
  Magmo3amodel magmo3aModel;

  StudentInAgroup({required this.magmo3aModel, super.key});

  @override
  State<StudentInAgroup> createState() => _StudentInAgroupState();
}

class _StudentInAgroupState extends State<StudentInAgroup> {
  final _searchController = TextEditingController();
  List<Studentmodel> filteredStudents = [];
  List<Studentmodel> allStudents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadInitialStudents();
  }

  Future<void> _loadInitialStudents() async {
    var stream = FirebaseFunctions.getStudentsByGroupId(
      widget.magmo3aModel.grade ?? "",
      widget.magmo3aModel.id,
    );

    stream.listen((snapshot) {
      final students = snapshot.docs.map((e) => e.data()).toList();
      setState(() {
        allStudents = students;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: app_colors.green),
            onPressed: () async {
              await _generatePdf(context);
            },
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: app_colors.green),
        ),
        backgroundColor: app_colors.darkGrey,
        title: Image.asset(
          "assets/images/logo.png",
          height: 100,
          width: 90,
        ),
        toolbarHeight: 150,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Center(child: Image.asset("assets/images/logo.png")),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: app_colors.darkGrey,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: TextFormField(
                              style:
                                  const TextStyle(color: app_colors.darkGrey),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'ابحث',
                                hintStyle:
                                    const TextStyle(color: app_colors.darkGrey),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 20.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: app_colors.green, width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: app_colors.green, width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: app_colors.green),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                              ),
                              cursorColor: app_colors.darkGrey,
                              controller: _searchController,
                            ),
                          ),
                          Text(
                            "عدد الطلاب في هذه المجموعة: ${allStudents.length}",
                            style: const TextStyle(
                              color: app_colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder(
                      stream: FirebaseFunctions.getStudentsByGroupId(
                        widget.magmo3aModel.grade ?? "",
                        widget.magmo3aModel.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: DiscreteCircle(
                              color: app_colors.darkGrey,
                              size: 30,
                              secondCircleColor: app_colors.ligthGreen,
                              thirdCircleColor: app_colors.green,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("حدث خطأ ما"),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('حاول مرة أخرى'),
                                ),
                              ],
                            ),
                          );
                        }

                        var students =
                            snapshot.data?.docs.map((e) => e.data()).toList() ??
                                [];
                        allStudents = students;
                        filteredStudents = students;

                        if (_searchController.text.isNotEmpty) {
                          filteredStudents = students.where((student) {
                            return student.name?.toLowerCase().contains(
                                    _searchController.text.toLowerCase()) ??
                                false;
                          }).toList();
                        }

                        if (students.isEmpty) {
                          return Center(
                            child: Text(
                              "لا يوجد طلاب",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 25, color: app_colors.black),
                            ),
                          );
                        }

                        return Expanded(
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 5),
                            itemBuilder: (context, index) {
                              return StudentWidget(
                                IsComingFromGroup: true,
                                grade: filteredStudents[index].grade,
                                studentModel: filteredStudents[index],
                              );
                            },
                            itemCount: filteredStudents.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font font = pw.Font.ttf(fontData);
    List<Studentmodel> pdfStudents = allStudents;

    final String formattedTime = widget.magmo3aModel.time != null
        ? '${widget.magmo3aModel.time!.hourOfPeriod == 0 ? 12 : widget.magmo3aModel.time!.hourOfPeriod}:${widget.magmo3aModel.time!.minute.toString().padLeft(2, '0')} ${(widget.magmo3aModel.time!.period == DayPeriod.am) ? 'صباحًا' : 'مساءً'}'
        : 'مجموعة بدون اسم';

    List<Studentmodel> boys =
        pdfStudents.where((s) => s.gender == 'Male').toList();
    List<Studentmodel> girls =
        pdfStudents.where((s) => s.gender == 'Female').toList();

    boys.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    girls.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    const int maxEntriesPerPage = 40;

    void addStudentPages(String title, List<Studentmodel> students, bool showGroupInfo) {
      for (int page = 0; page * maxEntriesPerPage < students.length; page++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (page == 0 && showGroupInfo) ...[
                    pw.Text("وقت المجموعة: $formattedTime",
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text("الصف: ${widget.magmo3aModel.grade ?? 'غير محدد'}",
                        textDirection:
                            _isArabic(widget.magmo3aModel.grade ?? '')
                                ? pw.TextDirection.rtl
                                : pw.TextDirection.ltr,
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text("اليوم: ${widget.magmo3aModel.days ?? 'غير محدد'}",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text("عدد الأولاد: ${boys.length}",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text("عدد البنات: ${girls.length}",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.Text("إجمالي عدد الطلاب: ${boys.length + girls.length}",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    pw.SizedBox(height: 10),
                    pw.Text(title,
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: students
                        .skip(page * maxEntriesPerPage)
                        .take(maxEntriesPerPage)
                        .map((student) => pw.Text(
                              student.name ?? 'بدون اسم',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(font: font, fontSize: 8),
                    ))
                        .toList(),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    addStudentPages("الأولاد:", boys, true);
    addStudentPages("البنات:", girls, true);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
