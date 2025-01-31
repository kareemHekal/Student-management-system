
import '../../models/Studentmodel.dart';

abstract class StudentEditState {}

class StudentEditInitial extends StudentEditState {}

class StudentEditLoading extends StudentEditState {}

class StudentEditSuccess extends StudentEditState {
  final Studentmodel updatedStudent;

  StudentEditSuccess({required this.updatedStudent});
}

class StudentEditFailure extends StudentEditState {
  final String errorMessage;

  StudentEditFailure({required this.errorMessage});
}