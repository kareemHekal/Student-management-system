import 'package:bloc/bloc.dart';
import 'package:fatma_elorbany/bloc/AddMogmo3a/add_mogmo3a_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase/firebase_functions.dart';
import '../../models/Magmo3aModel.dart';


class Magmo3aCubit extends Cubit<Magmo3aState> {
  Magmo3aCubit() : super(Magmo3aInitial());

  final List<String> days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  final List<String> secondaries = [
    '1 secondary',
    '2 secondary',
    '3 secondary',
  ];

  String? chosenDay;
  String? selectedSecondary;
  TimeOfDay timeOfDay = TimeOfDay.now();

  void selectDay(String day) {
    chosenDay = day;
    emit(Magmo3aDaySelected(day));
  }

  void selectSecondary(String secondary) {
    selectedSecondary = secondary;
    emit(Magmo3aSecondarySelected(secondary));
  }

  void pickTime(TimeOfDay time) {
    timeOfDay = time;
    emit(Magmo3aTimeSelected(time));
  }

  Future<void> addMagmo3a() async {
    if (chosenDay == null || selectedSecondary == null) {
      emit(Magmo3aError("Please fill all fields"));
      return;
    }

    emit(Magmo3aLoading());

    Magmo3amodel magmo3amodel = Magmo3amodel(
      userid: FirebaseAuth.instance.currentUser!.uid,
      days: chosenDay!,
      time: timeOfDay,
      grade: selectedSecondary!,
    );

    try {
      await FirebaseFunctions.addMagmo3aToDay(chosenDay!, magmo3amodel);
      emit(Magmo3aSuccess());
    } catch (e) {
      emit(Magmo3aError("Failed to add group"));
    }
  }
}
