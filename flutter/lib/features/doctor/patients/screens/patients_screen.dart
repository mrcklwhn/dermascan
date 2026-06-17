import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/patients/controller/patients_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientsScreen extends GetView<PatientsController> {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: <Widget>[
          Obx(
            () => IconButton(
              onPressed: controller.isInitializing.value
                  ? null
                  : controller.openAddNewPatientScreen,
              icon: const Icon(Icons.person_add),
              tooltip: 'Add Patient',
            ),
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
            'No Patients available',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Your practice currently has no patients.\nTo add new patients press the button below.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            onPressed: controller.isInitializing.value
                ? null
                : controller.openAddNewPatientScreen,
            label: const Text('Add Patient'),
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
            hintText: 'Search ...',
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
                            'Born on ${DateFormat('dd.MM.yyyy').format(patient.dateOfBirth)}',
                          ),
                          onTap: controller.isInitializing.value
                              ? null
                              : () => controller.openPatientProfile(
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
