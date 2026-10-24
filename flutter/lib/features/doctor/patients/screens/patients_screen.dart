import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/patients/controller/patients_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientsScreen extends GetView<PatientsController> {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TrKeys.patient.patients.tr),
        actions: <Widget>[
          IconButton(
              onPressed: controller.openAddNewPatientScreen,
              icon: const Icon(Icons.person_add),
              tooltip: TrKeys.patient.addPatient.tr,
            ),

        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (controller.patients.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildPatientList();
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: AppTheme.scaffoldPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),
          const CustomIcon(iconData: Icons.person_add),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            TrKeys.patient.noPatientsAvailable.tr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.patient.noPatientsFoundMsg.tr,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            onPressed: controller.openAddNewPatientScreen,
            label: Text(TrKeys.patient.addPatient.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return Padding(
      padding: AppTheme.scaffoldPadding.copyWith(top: 0, bottom: 0),
      child: Column(
        children: <Widget>[
          SearchBar(
            hintText: TrKeys.common.search.tr,
            controller: controller.searchBarController,
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              IconButton(
                onPressed: controller.clearSearchBar,
                icon: const Icon(Icons.clear),
              ),
            ],
            onChanged: (String value) =>
                controller.filterPatients(query: value),
            focusNode: controller.searchBarFocusNode,
            onTapOutside: (_) => controller.unfocusSearchBar(),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Obx(
            () => Expanded(
              child: ListView.builder(
                controller: controller.listScrollController,
                scrollDirection: Axis.vertical,
                itemCount: controller.visiblePatients.length,
                itemBuilder: (BuildContext context, int index) {
                  final Patient patient = controller.visiblePatients[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Card(
                        child: ListTile(
                          title: Text(patient.name),
                          leading: const Icon(Icons.person),
                          trailing: const Icon(Icons.arrow_forward),
                          subtitle: Text(
                            '${TrKeys.common.birthday.tr}: ${DateFormat('dd.MM.yyyy').format(patient.dateOfBirth)}',
                          ),
                          onTap: () => controller.openPatientProfile(
                                  patientId: patient.id,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
