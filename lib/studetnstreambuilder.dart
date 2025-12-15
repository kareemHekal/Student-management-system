import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../cards/StudentWidget.dart';
import '../firebase/firebase_functions.dart';
import 'models/Studentmodel.dart';
import 'theme/colors_app.dart';

class StudentStreamBuilder extends StatefulWidget {
  final String grade;

  StudentStreamBuilder({required this.grade, super.key});

  @override
  State<StudentStreamBuilder> createState() => _StudentStreamBuilderState();
}

class _StudentStreamBuilderState extends State<StudentStreamBuilder> {
  final _searchController = TextEditingController();
  List<Studentmodel> _filteredStudents = [];
  int numberofstudents = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredStudents.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMain,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print,
                                      color: Colors.white),
                                  onPressed: () async {
                                    if (_filteredStudents.isNotEmpty) {
                                      await _generatePdf(_filteredStudents);
                                    } else {
                                      print("لا يوجد طلاب للطباعة");
                                    }
                                  },
                                ),
                                Text(
                                  "عدد الطلاب: $numberofstudents",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: TextFormField(
                              style:
                                  const TextStyle(color: AppColors.primaryMain),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'ابحث عن الطالب',
                                hintStyle: const TextStyle(
                                    color: AppColors.primaryMain),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 20.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.secondaryMain,
                                      width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: AppColors.secondaryMain,
                                      width: 2.0),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.secondaryMain),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                              ),
                              cursorColor: AppColors.primaryMain,
                              controller: _searchController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<Studentmodel>>(
                        stream: FirebaseFunctions.getAllStudentsByGrade(
                            widget.grade),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Studentmodel>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('حدث خطأ: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (numberofstudents != 0) {
                                setState(() {
                                  numberofstudents = 0;
                                });
                              }
                            });
                            return Center(
                                child: Text(
                                    'لا يوجد طلاب للمرحلة: ${widget.grade}'));
                          }

                          var students = snapshot.data!;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (numberofstudents != students.length) {
                              setState(() {
                                numberofstudents = students.length;
                              });
                            }
                          });

                          if (_searchController.text.isNotEmpty) {
                            _filteredStudents = students.where((student) {
                              return student.name?.toLowerCase().contains(
                                      _searchController.text.toLowerCase()) ??
                                  false;
                            }).toList();
                          } else {
                            _filteredStudents = students;
                          }

                          return ListView.builder(
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return StudentWidget(
                                studentModel: student,
                                grade: widget.grade,
                                IsComingFromGroup: false,
                              );
                            },
                          );
                        },
                      ),
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
  _generatePdf(List<Studentmodel> students) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load("fonts/NotoKufiArabic-Regular.ttf");
    final pw.Font font = pw.Font.ttf(fontData);

    // Page dimensions for landscape A4
    final pageWidth = PdfPageFormat.a4.landscape.width;
    final pageHeight = PdfPageFormat.a4.landscape.height;

    const int crossAxisCount = 6; // 6 cards per row
    const double spacing = 10.0; // spacing between cards

    // Calculate card width
    final cardWidth =
        (pageWidth - (crossAxisCount + 1) * spacing) / crossAxisCount;

    // Compute the required height for each card based on the student with the longest name
    double computeCardHeight(
        List<Studentmodel> students, pw.Font font, double cardWidth) {
      double maxHeight = 80; // minimum height
      final textStyle = pw.TextStyle(font: font, fontSize: 10);
      final phoneStyle = pw.TextStyle(font: font, fontSize: 9);

      for (var s in students) {
        final name = s.name ?? "Unknown";
        final phone = s.phoneNumber ?? "لا يوجد رقم تلفون";

        // Estimate height for name and phone
        final nameLines =
            (name.length / 20).ceil(); // roughly 20 chars per line
        final phoneLines = 1;
        final totalLines = nameLines + phoneLines;

        final height = totalLines * 12 + 16; // 12pt per line + padding
        if (height > maxHeight) maxHeight = height as double;
      }
      return maxHeight;
    }

    final cardHeight = computeCardHeight(students, font, cardWidth);

    // Calculate maximum rows per page dynamically
    final maxRowsPerPage =
        ((pageHeight - spacing) / (cardHeight + spacing)).floor();

    final totalStudents = students.length;
    final totalCardsPerPage = crossAxisCount * maxRowsPerPage;
    final totalPages = (totalStudents / totalCardsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              children: List.generate(maxRowsPerPage, (rowIndex) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: List.generate(crossAxisCount, (colIndex) {
                    final studentIndex = pageIndex * totalCardsPerPage +
                        rowIndex * crossAxisCount +
                        colIndex;

                    if (studentIndex < totalStudents) {
                      final student = students[studentIndex];
                      final nameText = student.name ?? "Unknown";
                      final phoneNumber =
                          student.phoneNumber ?? "لا يوجد رقم تلفون";

                      return pw.Container(
                        width: cardWidth,
                        height: cardHeight,
                        padding: const pw.EdgeInsets.all(6),
                        margin: pw.EdgeInsets.all(spacing / 2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Row(
                          children: [
                            // Left side: name + phone
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    nameText,
                                    style:
                                        pw.TextStyle(font: font, fontSize: 10),
                                    maxLines: 2,
                                    overflow: pw.TextOverflow.clip,
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    "Phone: $phoneNumber",
                                    style: pw.TextStyle(
                                        font: font,
                                        fontSize: 9,
                                        color: PdfColors.grey800),
                                    textDirection: pw.TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                            // Right side: QR code
                            pw.Container(
                              width: 50,
                              height: 50,
                              child: pw.BarcodeWidget(
                                data: phoneNumber,
                                barcode: pw.Barcode.qrCode(),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Empty container for alignment
                      return pw.SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                      );
                    }
                  }),
                );
              }),
            );
          },
        ),
      );
    }

    // Print the document
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
