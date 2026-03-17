import 'package:dermascan/core/models/patient.dart';
import 'package:dermascan/core/widgets/patient_list_tile.dart';
import 'package:dermascan/features/doctor/patients/controller/patients_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientsScreen extends StatelessWidget {
  PatientsScreen({super.key});

  final PatientsController patientsController = Get.find<PatientsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        // Using headline style for consistency, though smaller for app bar
        title: Text(
          'Patients',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: patientsController.openCreateNewPatientScreen,
            icon: Icon(
              Icons.person_add_alt_1_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Add Patient',
          ),
          const SizedBox(width: 8), // Right padding for actions
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (patientsController.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (patientsController.patients.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildPatientList();
        }),
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: patientsController.patients.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Patient patient = patientsController.patients[index];
        return PatientListTile(
          patient: patient,
          onPressed: () =>
              patientsController.showPatientProfile(patientId: patient.id),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(),

          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'No Patients available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your practice currently has no patients.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          FilledButton.icon(
            onPressed: patientsController.openCreateNewPatientScreen,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Create new Patient'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
