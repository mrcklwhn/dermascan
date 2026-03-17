import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/widgets/doctor_list_tile.dart';
import 'package:dermascan/features/practice/doctors/controller/assigned_doctors_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AssignedDoctorsScreen extends StatelessWidget {
  AssignedDoctorsScreen({super.key});

  final AssignedDoctorsController assignedDoctorsController =
      Get.find<AssignedDoctorsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        // Using headline style for consistency, though smaller for app bar
        title: Text(
          'Team Members',
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
            onPressed: assignedDoctorsController.showPendingInvitations,
            icon: Icon(
              Icons.pending_actions,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Pending Invitations',
          ),
          IconButton(
            onPressed: assignedDoctorsController.showAvailableDoctors,
            icon: Icon(
              Icons.person_add_alt_1_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Add Doctor',
          ),
          const SizedBox(width: 8), // Right padding for actions
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (assignedDoctorsController.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (assignedDoctorsController.doctors.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildDoctorList();
        }),
      ),
    );
  }

  Widget _buildDoctorList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: assignedDoctorsController.doctors.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Doctor doctor = assignedDoctorsController.doctors[index];
        return DoctorListTile(
          doctor: doctor,
          onPressed: () =>
              assignedDoctorsController.showDoctorProfile(doctorId: doctor.id),
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
            'No Doctors Assigned',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your practice currently has no other doctors.\nInvite colleagues to collaborate on cases.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          FilledButton.icon(
            onPressed: assignedDoctorsController.showAvailableDoctors,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add Team Member'),
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
