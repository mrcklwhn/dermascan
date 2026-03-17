import 'package:dermascan/features/doctor/patients/controller/patient_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:human_body_selector/human_body_selector.dart';
import 'package:human_body_selector/svg_painter/maps.dart';
import 'package:human_body_selector/svg_painter/models/body_part.dart';

class PatientDetailsScreen extends StatelessWidget {
  PatientDetailsScreen({super.key});

  final PatientDetailsController patientDetailsController =
      Get.find<PatientDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(patientDetailsController.patient.name)),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            HumanBodySelector(
              map: Maps.HUMAN,
              onChanged: (List<BodyPart> bodyPart, BodyPart? active) {},
              onLevelChanged: (List<BodyPart> bodyPart) {},
              multiSelect: false,
              strokeColor: Colors.black,
              dotColor: Colors.transparent,
              toggle: true,
              selectedColor: Theme.of(context).primaryColor,
              height: MediaQuery.of(context).size.height,
              width: (MediaQuery.of(context).size.width / 2),
            ),
            HumanBodySelector(
              map: Maps.HUMAN1,
              onChanged: (List<BodyPart> bodyPart, BodyPart? active) {},
              onLevelChanged: (List<BodyPart> bodyPart) {},
              multiSelect: false,
              strokeColor: Colors.black,
              dotColor: Colors.transparent,
              toggle: true,
              selectedColor: Theme.of(context).primaryColor,
              height: MediaQuery.of(context).size.height,
              width: (MediaQuery.of(context).size.width / 2),
            ),
          ],
        ),
      ),
    );
  }
}
