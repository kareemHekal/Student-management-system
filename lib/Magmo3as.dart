import 'package:flutter/material.dart';
import 'cards/magmo3at/Magmo3aWidget.dart';
import 'firebase/firebase_functions.dart';
import 'models/Magmo3aModel.dart';
import 'theme/colors_app.dart';

class Magmo3as extends StatefulWidget {
  final String day; // إضافة final هنا كأفضل ممارسة

  const Magmo3as({required this.day, super.key});

  @override
  State<Magmo3as> createState() => _Magmo3asState();
}

class _Magmo3asState extends State<Magmo3as> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // السطر ده بيضمن إن الصفحة متتأثرش لو الكيبورد طلع فوقها وهي فاضية
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: StreamBuilder<List<Magmo3amodel>>(
          stream: FirebaseFunctions.getAllDocsFromDay(widget.day),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondaryMain,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("حدث شيء خطأ"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('حاول مرة أخرى'),
                    ),
                  ],
                ),
              );
            }

            var magmo3as = snapshot.data ?? [];

            // ترتيب المجموعات حسب الوقت
            magmo3as.sort((a, b) {
              final aMinutes = (a.time?.hour ?? 0) * 60 + (a.time?.minute ?? 0);
              final bMinutes = (b.time?.hour ?? 0) * 60 + (b.time?.minute ?? 0);
              return aMinutes.compareTo(bMinutes);
            });

            if (magmo3as.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد مجموعات",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 25,
                        color: AppColors.black,
                      ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Magmo3aWidget(
                  magmo3aModel: magmo3as[index],
                );
              },
              itemCount: magmo3as.length,
            );
          },
        ),
      ),
    );
  }
}