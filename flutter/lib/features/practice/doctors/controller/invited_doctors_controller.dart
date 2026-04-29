import 'dart:async';

import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/invitation.dart';
import 'package:dermascan/core/services/auth_service.dart';
import 'package:dermascan/core/services/db_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvitedDoctorsController extends GetxController {
  AuthService authService = Get.find<AuthService>();
  DBService dbService = Get.find<DBService>();

  ScrollController listScrollController = ScrollController();

  TextEditingController searchBarController = TextEditingController();

  FocusNode searchBarFocusNode = FocusNode();

  RxList<Doctor> doctors = <Doctor>[].obs;
  RxList<Doctor> visibleDoctors = <Doctor>[].obs;

  RxBool isInitializing = true.obs;

  @override
  void onClose() {
    listScrollController.dispose();
    searchBarController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    try {
      await loadInvitedDoctors();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading invited doctors: $e');
      }
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> loadInvitedDoctors() async {
    final String? practiceId = authService.currentUser.value?.id;

    if (practiceId == null) {
      return;
    }

    final List<PracticeInvitation> invitations = await dbService
        .fetchInvitedDoctors(practiceId: practiceId);

    final List<Doctor> invitedDoctors = invitations
        .map((PracticeInvitation invitation) => invitation.doctor)
        .toList();

    doctors.assignAll(invitedDoctors);
    visibleDoctors.assignAll(invitedDoctors);
  }

  Future<void> reloadDoctors() async {
    if (isInitializing.value) return;

    isInitializing.value = true;
    unawaited(_initializeData());
  }

  void filterDoctors({required String query}) {
    if (query.isEmpty) {
      visibleDoctors.assignAll(doctors);
    } else {
      final Iterable<Doctor> filtered = doctors.where(
        (Doctor p) => p.name.toLowerCase().contains(query.toLowerCase()),
      );
      visibleDoctors.assignAll(filtered);
    }
  }

  void unfocusSearchBar() {
    searchBarFocusNode.unfocus();
  }

  void clearSearchBar() {
    searchBarController.clear();
    filterDoctors(query: searchBarController.value.text);
  }

  void removeDoctor({required String doctorId}) {
    doctors.removeWhere(((Doctor doctor) => doctor.id == doctorId));
    visibleDoctors.removeWhere(((Doctor doctor) => doctor.id == doctorId));
  }

  void addDoctor({required Doctor doctor}) {
    doctors.add(doctor);
    visibleDoctors.add(doctor);
  }

  void showDoctorProfile({required String doctorId}) {
    if (isInitializing.value) return;

    final Doctor selectedDoctor = doctors.firstWhere(
      (Doctor doc) => doc.id == doctorId,
    );

    Get.toNamed(
      '/practice/doctor-details',
      arguments: <String, Object>{
        'doctor': selectedDoctor,
        'assignedToCurrentPractice': false,
        'invitationSent': true,
        'removeFromList': removeDoctor,
        'addToList': addDoctor,
      },
    );
  }
}
