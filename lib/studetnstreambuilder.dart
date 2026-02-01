import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // يفضل استخدامه لتوحيد التجربة

import '../firebase/firebase_functions.dart';
import 'BottomSheets/student_chosen_pdf.dart';
import 'cards/student/StudentWidget.dart';
import 'models/Student_model.dart';
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
    // الحصول على بيانات الشاشة لضبط الأبعاد
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      // تجنب لوحة المفاتيح من تغطية العناصر
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // اللوجو في الخلفية مع تقليل الشفافية لضمان قراءة النصوص
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Center(child: Image.asset("assets/images/logo.png")),
              ),
            ),
          ),
          Column(
            children: [
              // الهيدر الملون مع مرونة في الارتفاع
              _buildHeader(context),

              // مساحة البحث والنتائج
              Expanded(
                child: StreamBuilder<List<Studentmodel>>(
                  stream: FirebaseFunctions.getAllStudentsByGrade(widget.grade),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      _updateCount(0);
                      return Center(
                        child: Text(
                          'لا يوجد طلاب للمرحلة: ${widget.grade}',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                      );
                    }

                    var students = snapshot.data!;
                    _updateCount(students.length);

                    // تصفية الطلاب بناءً على البحث
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
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return StudentWidget(
                          studentModel: _filteredStudents[index],
                          IsComingFromGroup: false,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // هيدر مرن يتكيف مع حجم الخط
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      // أزلنا الارتفاع الثابت (height: 140) واستبدلناه بـ Padding و Constraints
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 15,
        right: 15,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // السطر الأول: الأيقونة والعدد
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            children: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white, size: 28),
                onPressed: () {
                  StudentChosenPdf.show(
                      context: context, students: _filteredStudents);
                },
              ),
              // استخدام FittedBox لمنع انكسار النص عند الأرقام الكبيرة
              FittedBox(
                child: Text(
                  "عدد الطلاب: $numberofstudents",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // حقل البحث
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      // حماية للشاشات العريضة (Tablets)
      child: TextFormField(
        controller: _searchController,
        style: GoogleFonts.cairo(color: AppColors.primaryMain, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'ابحث عن اسم الطالب...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryMain),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(15.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: AppColors.secondaryMain, width: 2),
            borderRadius: BorderRadius.circular(15.0),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  // دالة مساعدة لتحديث العدد بأمان خارج مرحلة البناء
  void _updateCount(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && numberofstudents != count) {
        setState(() {
          numberofstudents = count;
        });
      }
    });
  }
}