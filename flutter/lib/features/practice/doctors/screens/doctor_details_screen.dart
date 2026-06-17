import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/practice/doctors/controller/doctor_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DoctorDetailsScreen extends GetView<DoctorDetailsController> {
  const DoctorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Details')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitializing.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          return _buildProfile(context);
        }),
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final Doctor doctor = controller.doctor;

    return ListView(
      controller: controller.scrollController,
      padding: AppTheme.scaffoldPadding,
      children: <Widget>[
        const CustomIcon(iconData: Icons.person),
        const SizedBox(height: AppTheme.spaceLarge),

        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: AppTheme.spaceSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(doctor.name),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Date of Birth'),
            subtitle: Text(DateFormat('dd.MM.yyyy').format(doctor.dateOfBirth)),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        Text('Contact Details', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: AppTheme.spaceSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('E-Mail'),
            subtitle: Text(doctor.email),
          ),
        ),

        const SizedBox(height: AppTheme.spaceLarge),
        Obx(() {
          if (controller.isAssignedToCurrentPractice.value) {
            return OutlinedButton.icon(
              onPressed:
                  controller.isInitializing.value ||
                      controller.isLoading.value ||
                      !controller.isAssignedToCurrentPractice.value
                  ? null
                  : controller.showRemoveDialog,
              icon: const Icon(Icons.person_remove),
              label: const Text('Remove Doctor'),
            );
          } else if (controller.invitationSent.value) {
            return OutlinedButton.icon(
              onPressed:
                  controller.isInitializing.value ||
                      controller.isLoading.value ||
                      !controller.invitationSent.value
                  ? null
                  : controller.showRevokeDialog,
              icon: const Icon(Icons.clear),
              label: const Text('Revoke Invitation'),
            );
          } else {
            return OutlinedButton.icon(
              onPressed:
                  controller.isInitializing.value ||
                      controller.isLoading.value ||
                      controller.invitationSent.value
                  ? null
                  : controller.showInviteDialog,
              icon: const Icon(Icons.outgoing_mail),
              label: const Text('Invite Doctor'),
            );
          }
        }),
      ],
    );
  }
}
