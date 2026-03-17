import 'package:dermascan/features/practice/doctors/screens/assigned_doctors_screen.dart';
import 'package:dermascan/features/practice/profile/screens/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class PracticeHomeController extends GetxController {
  Rx<int> currentScreenIndex = 0.obs;

  final List<Widget> screens = <Widget>[
    AssignedDoctorsScreen(),
    PracticeProfileScreen(),
  ];
}
