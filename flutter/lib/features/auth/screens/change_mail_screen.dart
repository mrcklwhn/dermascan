import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/change_mail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeEmailScreen extends GetView<ChangeEmailController> {
  const ChangeEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change E-Mail'.tr)),
      body: ListView(
        controller: controller.scrollController,
        scrollDirection: Axis.vertical,
        padding: AppTheme.scaffoldPadding,
        children: <Widget>[
          const CustomIcon(iconData: Icons.mail),
          const SizedBox(height: AppTheme.spaceLarge),
          CustomTextField(
            textEditingController: controller.newEmailController,
            focusNode: controller.newEmailFocusNode,
            onSubmitted: (_) => controller.submitNewPassword(),
            labelText: 'New E-Mail'.tr,
            prefixIcon: Icons.mail,
            textInputType: TextInputType.emailAddress,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'Correctly formatted'.tr,
                criteriaState: controller.isValidEmail,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          CustomTextField(
            textEditingController: controller.confirmNewEmailController,
            focusNode: controller.confirmNewEmailFocusNode,
            onSubmitted: controller.isLoading.value
                ? (_) {}
                : (_) => controller.submitChangedEmail(),
            labelText: 'Confirm new E-Mail'.tr,
            prefixIcon: Icons.mail,
            textInputType: TextInputType.emailAddress,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'E-Mails match'.tr,
                criteriaState: controller.emailsMatch,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.submitChangedEmail,
              child: Text('Submit'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
