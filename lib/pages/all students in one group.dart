import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_management_system/BottomSheets/student_chosen_pdf.dart';

import '../cards/student/StudentWidget.dart';
import '../firebase/firebase_functions.dart';
import '../models/Magmo3aModel.dart';
import '../models/Student_model.dart';
import '../theme/colors_app.dart';

class AllStudedntsInOneGroup extends StatefulWidget {
  final Magmo3amodel magmo3aModel;

  const AllStudedntsInOneGroup({required this.magmo3aModel, super.key});

  @override
  State<AllStudedntsInOneGroup> createState() => _AllStudedntsInOneGroupState();
}

class _AllStudedntsInOneGroupState extends State<AllStudedntsInOneGroup> {
  final _searchController = TextEditingController();
  List<Studentmodel> _allStudents = []; // المخزن الأصلي
  List<Studentmodel> _filteredStudents = []; // اللي بيظهر في القائمة
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentsOnce(); // بنجيب البيانات مرة واحدة بس
  }

  // دالة جلب البيانات الموفرة (استهلاك Reads لمرة واحدة فقط)
  Future<void> _fetchStudentsOnce() async {
    try {
      final snapshot = await FirebaseFunctions.getSecondaryCollection(
              widget.magmo3aModel.grade ?? "")
          .where("hisGroupsId", arrayContains: widget.magmo3aModel.id)
          .get(); // استخدام get() بدل snapshots() هو السر

      final students = snapshot.docs.map((doc) => doc.data()).toList();

      // ترتيب الطلاب أبجدياً لسهولة الوصول
      students.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));

      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // البحث المحلي (صفر Reads وصفر تأخير)
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
            icon: const Icon(Icons.picture_as_pdf,
                color: AppColors.secondaryMain),
            onPressed: () {
              // طباعة الطلاب المعروضين حالياً (لو باحث عن حد هيطبع المفلتر بس)
              StudentChosenPdf.show(
                  context: context, students: _filteredStudents);
            },
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.secondaryMain),
        ),
        backgroundColor: AppColors.primaryMain,
        title: Image.asset("assets/images/logo.png", height: 80, width: 80),
        toolbarHeight: 120,
        // صغرنا الارتفاع شوية عشان الـ UI يكون ألطف
        elevation: 0,
      ),
      body: Stack(
        children: [
          // اللوجو الخلفي
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Center(
                  child: Image.asset("assets/images/logo.png", width: 200)),
            ),
          ),
          Column(
            children: [
              // كارت البحث والعدد
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
                decoration: const BoxDecoration(
                  color: AppColors.primaryMain,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: AppColors.primaryMain),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'ابحث عن اسم الطالب...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primaryMain),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged("");
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "عدد الطلاب في هذه المجموعة: ${_filteredStudents.length}",
                      style: GoogleFonts.cairo(
                        color: AppColors.secondaryMain,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryMain))
                    : RefreshIndicator(
                        color: AppColors.primaryMain,
                        onRefresh: _fetchStudentsOnce, // تحديث بيانات المجموعة
                        child: _filteredStudents.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                      height: 200,
                                      child: Center(
                                          child: Text(
                                              "لا يوجد طلاب مطابقين للبحث")))
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(15),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  return StudentWidget(
                                    IsComingFromGroup: true,
                                    studentModel: _filteredStudents[index],
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
}