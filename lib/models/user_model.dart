// This file re-exports the canonical UserModel so that any code importing
// 'package:bharat_problem_solver/models/user_model.dart' gets the same type
// as 'package:bharat_problem_solver/data/models/user_model.dart'.
// This resolves the "UserModel/*1*/ can't be assigned to UserModel/*2*/" error.
export '../data/models/user_model.dart';
