import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/change_mail_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeEmailScreen extends GetView<ChangeEmailController> {
  const ChangeEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.auth.changeEmail.tr)),
      body: SingleChildScrollView(
        padding: AppTheme.scaffoldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const CustomIcon(iconData: Icons.mail),
            const SizedBox(height: AppTheme.spaceLarge),
            CustomTextField(
              textEditingController: controller.newEmailController,
              focusNode: controller.newEmailFocusNode,
              onSubmitted: (_) => controller.submitNewPassword(),
              labelText: TrKeys.auth.newEmail.tr,
              prefixIcon: Icons.mail,
              textInputType: TextInputType.emailAddress,
              checkCriteria: <CheckCriteria>[
                CheckCriteria(
                  criteriaName: TrKeys.auth.correctlyFormatted.tr,
                  criteriaState: controller.isValidEmail,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            CustomTextField(
              textEditingController: controller.confirmNewEmailController,
              focusNode: controller.confirmNewEmailFocusNode,
              onSubmitted: (_) => controller.submitChangedEmail(),
              labelText: TrKeys.auth.confirmNewEmail.tr,
              prefixIcon: Icons.mail,
              textInputType: TextInputType.emailAddress,
              checkCriteria: <CheckCriteria>[
                CheckCriteria(
                  criteriaName: TrKeys.auth.emailsMatch.tr,
                  criteriaState: controller.emailsMatch,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            ElevatedButton(
                onPressed: controller.submitChangedEmail,
                child: Text(TrKeys.common.submit.tr),
              ),

          ],
        ),
      ),
    );
  }
}
