import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../firebase/firebase_functions.dart';
import '../../BottomSheets/student_chosen_pdf.dart';
import '../../cards/student/StudentWidget.dart';
import '../../models/Student_model.dart';
import '../../theme/colors_app.dart';

class StudentListBuilder extends StatefulWidget {
  final String grade;

  const StudentListBuilder({required this.grade, super.key});

  @override
  State<StudentListBuilder> createState() => _StudentListBuilderState();
}

class _StudentListBuilderState extends State<StudentListBuilder> {
  final _searchController = TextEditingController();

  // القوائم المحلية للتحكم في البيانات دون الرجوع لـ Firebase
  List<Studentmodel> _allStudents = [];
  List<Studentmodel> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // جلب البيانات مرة واحدة فقط (صفر استهلاك Reads إضافي عند البحث)
  Future<void> _fetchInitialData() async {
    try {
      final snapshot =
          await FirebaseFunctions.getSecondaryCollection(widget.grade).get();
      _allStudents = snapshot.docs.map((doc) => doc.data()).toList();

      // ترتيب الطلاب أبجدياً بالمرة
      _allStudents.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));

      _filteredStudents = _allStudents;
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // دالة البحث المحلي - طلقة في السرعة وصفر تكلفة
  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents
            .where((student) =>
                student.name!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackgroundLogo(),
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                        color: AppColors.primaryMain,
                      ))
                    : RefreshIndicator(
                        color: AppColors.primaryMain,
                        onRefresh: _fetchInitialData,
                        // هينادي الدالة اللي بتحدث من الكاش/السيرفر
                        child: _filteredStudents.isEmpty
                            ? ListView(
                                // عشان الـ refresh يشتغل والقائمة فاضية
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                      height: 200, child: _buildEmptyState())
                                ],
                              )
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // مهمة جداً
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 20),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  return StudentWidget(
                                    studentModel: _filteredStudents[index],
                                    IsComingFromGroup: false,
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white, size: 28),
                onPressed: () {
                  // هنا هيرسل القائمة المفلترة حالياً فقط للطباعة (زي ما أنت عايز)
                  StudentChosenPdf.show(
                      context: context, students: _filteredStudents);
                },
              ),
              Text(
                "عدد الطلاب: ${_filteredStudents.length}",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      onChanged: _onSearchChanged, // البحث هنا محلي وفوري
      style: GoogleFonts.cairo(color: AppColors.primaryMain, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'ابحث عن اسم الطالب...',
        hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryMain),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged("");
                },
              )
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBackgroundLogo() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Center(child: Image.asset("assets/images/logo.png")),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا يوجد طلاب للمرحلة: ${widget.grade}',
        style: GoogleFonts.cairo(fontSize: 16),
      ),
    );
  }
}