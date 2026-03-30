import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/practice/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PracticeProfileScreen extends GetView<PracticeProfileController> {
  const PracticeProfileScreen({super.key});

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
    final User? user = controller.authService.currentUser.value;

    return ListView(
      controller: controller.scrollController,
      padding: AppTheme.scaffoldPadding,
      children: <Widget>[
        const CustomIcon(iconData: Icons.local_hospital),
        const SizedBox(height: AppTheme.spaceLarge),
        CustomTextField(
          textEditingController: controller.nameController,
          focusNode: controller.nameFocusNode,
          onSubmitted:
              controller.isInitializing.value || controller.isLoading.value
              ? (_) {}
              : (String value) => controller.submitName(newName: value),
          labelText: 'Name',
          prefixIcon: Icons.local_hospital,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: AppTheme.spaceLarge),
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
