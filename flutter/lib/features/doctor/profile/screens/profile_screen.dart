import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorProfileScreen extends GetView<DoctorProfileController> {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
    final Practice? practice = controller.authService.currentPractice.value;
    final User? user = controller.authService.currentUser.value;
    final Doctor? doctor = controller.authService.currentDoctor.value;

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
        CustomTextField(
          textEditingController: controller.nameController,
          focusNode: controller.nameFocusNode,
          onSubmitted:
              controller.isInitializing.value || controller.isLoading.value
              ? (_) {}
              : (String value) => controller.submitName(newName: value),
          labelText: 'Name',
          prefixIcon: Icons.person,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Date of Birth'),
            subtitle: doctor == null
                ? const Text('None')
                : Text(DateFormat('dd.MM.yyyy').format(doctor.dateOfBirth)),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        Text(
          'Practice Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: AppTheme.spaceSmall),

        Card(
          child: ListTile(
            leading: const Icon(Icons.local_hospital),
            title: const Text('Current Practice'),
            subtitle: practice == null
                ? const Text('None')
                : Text('Name: ${practice.name}\nE-Mail: ${practice.email}'),
            trailing: const Icon(Icons.logout),
            onTap: controller.isInitializing.value || controller.isLoading.value
                ? null
                : controller.showLeavePracticeDialog,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        Text(
          'Security & Account',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: AppTheme.spaceSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Change E-Mail'),
            subtitle: Text(_buildEmailText(user)),
            trailing: const Icon(Icons.arrow_forward),
            onTap: controller.isInitializing.value || controller.isLoading.value
                ? null
                : controller.openChangeEmailScreen,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Card(
          child: ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: controller.isInitializing.value || controller.isLoading.value
                ? null
                : controller.openChangePasswordScreen,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        OutlinedButton.icon(
          onPressed:
              controller.isInitializing.value || controller.isLoading.value
              ? null
              : controller.showLogoutDialog,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  String _buildEmailText(User? user) {
    if (user == null) return 'None';

    final String? email = user.email;
    final String? newEmail = user.newEmail;

    if (newEmail == null || newEmail == email) {
      return 'Currently: $email';
    }

    return 'Currently: $email\n'
        'Pending: $newEmail\n'
        'Please verify email and login again.';
  }
}
