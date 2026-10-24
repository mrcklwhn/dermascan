import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/doctor.dart';
import 'package:dermascan/core/models/practice.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/doctor/profile/controller/profile_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorProfileScreen extends GetView<DoctorProfileController> {
  const DoctorProfileScreen({super.key});

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
    final Practice? practice = controller.authService.currentPractice.value;
    final User? user = controller.authService.currentUser.value;
    final Doctor? doctor = controller.authService.currentDoctor.value;

    return SingleChildScrollView(
      padding: AppTheme.scaffoldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const CustomIcon(iconData: Icons.person),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            TrKeys.doctor.doctorInformation.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          CustomTextField(
            textEditingController: controller.nameController,
            focusNode: controller.nameFocusNode,
            onSubmitted: (String value) => controller.submitName(newName: value),
            labelText: TrKeys.common.name.tr,
            prefixIcon: Icons.person,
            textInputType: TextInputType.name,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(TrKeys.common.dateOfBirth.tr),
              subtitle: doctor == null
                  ? Text(TrKeys.common.notAvailable.tr)
                  : Text(DateFormat('dd.MM.yyyy').format(doctor.dateOfBirth)),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

        Text(
          TrKeys.practice.practiceDetails.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: AppTheme.spaceSmall),

          Card(
            child: ListTile(
              leading: const Icon(Icons.local_hospital),
              title: Text(TrKeys.practice.currentPractice.tr),
              subtitle: practice == null
                  ? Text(TrKeys.common.notAvailable.tr)
                  : Text(
                '${TrKeys.common.name.tr}: ${practice.name}\n${TrKeys.common.email.tr}: ${practice.email}',
              ),
              trailing: const Icon(Icons.logout),
              onTap: controller.showLeavePracticeDialog,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            TrKeys.common.securityAndAccount.tr,
            style: Theme.of(context).textTheme.titleMedium,
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
