import 'package:dermascan/core/widgets/human_body_selector.dart';
import 'package:dermascan/features/doctor/patients/controller/patient_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientDetailsScreen extends GetView<PatientDetailsController> {
  const PatientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.patient.name)),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            HumanBodySelector(
              map: BodySelectorMaps.maleFront,
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
              map: BodySelectorMaps.maleBack,
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
