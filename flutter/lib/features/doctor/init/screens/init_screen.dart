import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/features/doctor/init/controller/init_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorInitScreen extends GetView<DoctorInitController> {
  const DoctorInitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              const CustomIcon(iconData: Icons.local_hospital),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'No Practice Assigned'.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'You are currently not a member of any practice.\nPlease check your inbox for invitations to join a team.'
                    .tr,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.local_hospital),
                onPressed: controller.openInvitationsScreen,
                label: Text('Check Invitations'.tr),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                onPressed: controller.showLogoutDialog,
                label: Text('Logout'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
