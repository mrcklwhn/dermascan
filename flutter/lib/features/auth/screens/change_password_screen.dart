import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/change_password_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TrKeys.auth.changePassword.tr)),
      body: SingleChildScrollView(
        padding: AppTheme.scaffoldPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const CustomIcon(iconData: Icons.password),
            const SizedBox(height: AppTheme.spaceLarge),
            CustomTextField(
              textEditingController: controller.newPasswordController,
              focusNode: controller.newPasswordFocusNode,
              onSubmitted: (_) => controller.submitNewPassword(),
              labelText: TrKeys.auth.newPassword.tr,
              prefixIcon: Icons.password,
              textInputType: TextInputType.visiblePassword,
              checkCriteria: <CheckCriteria>[
                CheckCriteria(
                  criteriaName: TrKeys.auth.minLength8.tr,
                  criteriaState: controller.hasMinLength,
                ),
                CheckCriteria(
                  criteriaName: TrKeys.auth.containsUppercase.tr,
                  criteriaState: controller.hasUppercase,
                ),
                CheckCriteria(
                  criteriaName: TrKeys.auth.containsLowercase.tr,
                  criteriaState: controller.hasLowercase,
                ),
                CheckCriteria(
                  criteriaName: TrKeys.auth.containsDigit.tr,
                  criteriaState: controller.hasDigits,
                ),
                CheckCriteria(
                  criteriaName: TrKeys.auth.containsSpecialChar.tr,
                  criteriaState: controller.hasSpecialCharacters,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            CustomTextField(
              textEditingController: controller.confirmNewPasswordController,
              focusNode: controller.confirmNewPasswordFocusNode,
              onSubmitted: (_) => controller.submitChangedPassword(),
              labelText: TrKeys.auth.confirmNewPassword.tr,
              prefixIcon: Icons.password,
              textInputType: TextInputType.visiblePassword,
              checkCriteria: <CheckCriteria>[
                CheckCriteria(
                  criteriaName: TrKeys.auth.passwordsMatch.tr,
                  criteriaState: controller.passwordsMatch,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            ElevatedButton(
                onPressed: controller.submitChangedPassword,
                child: Text(TrKeys.common.submit.tr),
              ),

          ],
        ),
      ),
    );
  }
}
