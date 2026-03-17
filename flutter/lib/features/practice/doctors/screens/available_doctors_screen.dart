import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/widgets/doctor_list_tile.dart';
import 'package:dermascan/features/practice/doctors/controller/available_doctors_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AvailableDoctorsScreen extends StatelessWidget {
  AvailableDoctorsScreen({super.key});

  final AvailableDoctorsController availableDoctorsController =
      Get.find<AvailableDoctorsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Available Doctors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        if (availableDoctorsController.isInitializing.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (availableDoctorsController.doctors.isEmpty) {
          // Empty state matching the standard layout
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                      Icons.person_off_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No Doctors Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'There are currently no doctors available in the list.\nPlease try again later or contact support.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // List state with standard padding
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          itemCount: availableDoctorsController.doctors.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 16),
          itemBuilder: (BuildContext context, int index) {
            final Doctor doctor = availableDoctorsController.doctors[index];
            return DoctorListTile(
              doctor: doctor,
              onPressed: () => availableDoctorsController.showDoctorProfile(
                doctorId: doctor.id,
              ),
            );
          },
        );
      }),
    );
  }
}
