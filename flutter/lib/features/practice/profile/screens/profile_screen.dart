import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/practice/profile/controller/profile_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PracticeProfileScreen extends GetView<PracticeProfileController> {
  const PracticeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.doctor.profile.tr)),
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

    return SingleChildScrollView(
      padding: AppTheme.scaffoldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const CustomIcon(iconData: Icons.local_hospital),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            TrKeys.practice.practiceInformation.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          CustomTextField(
            textEditingController: controller.nameController,
            focusNode: controller.nameFocusNode,
            onSubmitted: (String value) => controller.submitName(newName: value),
            labelText: TrKeys.common.name.tr,
            prefixIcon: Icons.local_hospital,
            textInputType: TextInputType.name,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.common.securityAndAccount.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(TrKeys.practice.exportEncryptionKey.tr),
              subtitle: Text(TrKeys.practice.showQrCodeToDoctors.tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: controller.openKeyExportDialog,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail),
              title: Text(TrKeys.auth.changeEmail.tr),
              subtitle: Text(_buildEmailText(user)),
              trailing: const Icon(Icons.arrow_forward),
              onTap: controller.openChangeEmailScreen,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.password),
              title: Text(TrKeys.auth.changePassword.tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: controller.openChangePasswordScreen,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.help.helpAndDocumentation.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(TrKeys.help.documentation.tr),
              trailing: const Icon(Icons.arrow_forward),
              onTap: controller.openDocumentationScreen,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          OutlinedButton.icon(
            onPressed: controller.showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: Text(TrKeys.common.logout.tr),
          ),
        ],
      ),
    );
  }

  String _buildEmailText(User? user) {
    if (user == null) return TrKeys.common.notAvailable.tr;

    final String? email = user.email;
    final String? newEmail = user.newEmail;

    if (newEmail == null || newEmail == email) {
      return '${TrKeys.common.currently.tr}: $email';
    }

    return '${TrKeys.common.currently.tr}: $email\n${TrKeys.common.pending.tr}: $newEmail\n${TrKeys.auth.verifyEmailMsg.tr}';
  }
}
