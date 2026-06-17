import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/change_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password'.tr)),
      body: ListView(
        controller: controller.scrollController,
        scrollDirection: Axis.vertical,
        padding: AppTheme.scaffoldPadding,
        children: <Widget>[
          const CustomIcon(iconData: Icons.mail),
          const SizedBox(height: AppTheme.spaceLarge),
          CustomTextField(
            textEditingController: controller.newPasswordController,
            focusNode: controller.newPasswordFocusNode,
            onSubmitted: (_) => controller.submitNewPassword(),
            labelText: 'New Password'.tr,
            prefixIcon: Icons.password,
            textInputType: TextInputType.visiblePassword,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'Contains at least 8 characters'.tr,
                criteriaState: controller.hasMinLength,
              ),
              CheckCriteria(
                criteriaName: 'Contains an uppercase letter'.tr,
                criteriaState: controller.hasUppercase,
              ),
              CheckCriteria(
                criteriaName: 'Contains a lowercase letter'.tr,
                criteriaState: controller.hasLowercase,
              ),
              CheckCriteria(
                criteriaName: 'Contains a digit'.tr,
                criteriaState: controller.hasDigits,
              ),
              CheckCriteria(
                criteriaName: 'Contains special character'.tr,
                criteriaState: controller.hasSpecialCharacters,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          CustomTextField(
            textEditingController: controller.confirmNewPasswordController,
            focusNode: controller.confirmNewPasswordFocusNode,
            onSubmitted: controller.isLoading.value
                ? (_) {}
                : (_) => controller.submitChangedPassword(),
            labelText: 'Confirm new Password'.tr,
            prefixIcon: Icons.password,
            textInputType: TextInputType.visiblePassword,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'Passwords match'.tr,
                criteriaState: controller.passwordsMatch,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.submitChangedPassword,
              child: Text('Submit'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
