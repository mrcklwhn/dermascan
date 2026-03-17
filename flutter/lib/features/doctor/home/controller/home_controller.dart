import 'package:dermascan/features/doctor/patients/screens/patients_screen.dart';
import 'package:dermascan/features/doctor/profile/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class DoctorHomeController extends GetxController {
  Rx<int> currentScreenIndex = 0.obs;

  final List<Widget> screens = <Widget>[
    PatientsScreen(),
    DoctorProfileScreen(),
  ];
}
