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
      appBar: AppBar(title: Text('Profile'.tr)),
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

        Text(
          'Practice Information'.tr,
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
          labelText: 'Name'.tr,
          prefixIcon: Icons.local_hospital,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        Text(
          'Security & Account'.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: AppTheme.spaceSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.mail),
            title: Text('Change E-Mail'.tr),
            subtitle: Text(_buildEmailText(user)),
            trailing: const Icon(Icons.arrow_forward),
            onTap: controller.isInitializing.value || controller.isLoading.value
                ? null
                : controller.openChangeEmailScreen,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Card(
          child: ListTile(
            leading: const Icon(Icons.password),
            title: Text('Change Password'.tr),
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
          label: Text('Logout'.tr),
        ),
      ],
    );
  }

  String _buildEmailText(User? user) {
    if (user == null) return 'Not available';

    final String? email = user.email;
    final String? newEmail = user.newEmail;

    if (newEmail == null || newEmail == email) {
      return '${'Currently'.tr}: $email';
    }

    return '${'Currently'.tr}: $email\n${'Pending'.tr}: $newEmail\n${'Please verify email and login again.'.tr}';
  }
}
