import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/login/doctor_login_controller.dart';
import 'package:dermascan/features/auth/controller/login/login_controller.dart';
import 'package:dermascan/features/auth/controller/login/practice_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => ListView(
            controller: controller.scrollController,
            scrollDirection: Axis.vertical,
            padding: AppTheme.scaffoldPadding.copyWith(
              top: AppTheme.spaceLarge,
            ),
            children: <Widget>[
              const CustomIcon(iconData: Icons.login),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Welcome Back!'.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),
              CustomTextField(
      textEditingController: doctorLoginController.emailController,
      focusNode: doctorLoginController.emailFocusNode,
      onSubmitted: (_) => doctorLoginController.submittedEmail(),
      labelText: 'E-Mail'.tr,
      prefixIcon: Icons.email,
      textInputType: TextInputType.emailAddress,
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorLoginController.passwordController,
      focusNode: doctorLoginController.passwordFocusNode,
      onSubmitted: doctorLoginController.loginController.isLoading.value
          ? (_) {}
          : (_) => doctorLoginController.submitLoginData(),
      labelText: 'Password'.tr,
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    FilledButton.icon(
      icon: const Icon(Icons.login),
      onPressed: doctorLoginController.loginController.isLoading.value
          ? null
          : doctorLoginController.submitLoginData,
      label: Text('Login'.tr),
    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Obx(() {
          return Padding(
            padding: AppTheme.scaffoldPadding,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.app_registration),
              onPressed: controller.isLoading.value
                  ? null
                  : controller.navigateToRegister,
              label: Text('Create Account'.tr),
            ),
          );
        }),
      ),
    );
  }
}
