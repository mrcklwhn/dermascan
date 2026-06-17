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
      appBar: AppBar(title: const Text('Change E-Mail')),
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
            labelText: 'New Password',
            prefixIcon: Icons.password,
            textInputType: TextInputType.visiblePassword,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'Contains at least 8 characters',
                criteriaState: controller.hasMinLength,
              ),
              CheckCriteria(
                criteriaName: 'Contains an uppercase letter',
                criteriaState: controller.hasUppercase,
              ),
              CheckCriteria(
                criteriaName: 'Contains a lowercase letter',
                criteriaState: controller.hasLowercase,
              ),
              CheckCriteria(
                criteriaName: 'Contains a digit',
                criteriaState: controller.hasDigits,
              ),
              CheckCriteria(
                criteriaName: 'Contains special character',
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
            labelText: 'Confirm new Password',
            prefixIcon: Icons.password,
            textInputType: TextInputType.visiblePassword,
            checkCriteria: <CheckCriteria>[
              CheckCriteria(
                criteriaName: 'Passwords match',
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
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
