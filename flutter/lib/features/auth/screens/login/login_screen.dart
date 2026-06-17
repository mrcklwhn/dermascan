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
              SegmentedButton<AuthOption>(
                showSelectedIcon: false,
                segments: <ButtonSegment<AuthOption>>[
                  ButtonSegment<AuthOption>(
                    value: AuthOption.doctor,
                    label: Text('Doctor'.tr),
                    icon: const Icon(Icons.medical_services_outlined),
                  ),
                  ButtonSegment<AuthOption>(
                    value: AuthOption.practice,
                    label: Text('Practice'.tr),
                    icon: const Icon(Icons.business_outlined),
                  ),
                ],
                selected: <AuthOption>{
                  controller.currentSelectedAuthOption.value,
                },
                onSelectionChanged: (Set<AuthOption> newSelection) =>
                    controller.changeCurrentSelectedAuthOption(
                      newAuthOption: newSelection.first,
                    ),
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              if (controller.currentSelectedAuthOption.value ==
                  AuthOption.doctor)
                ...buildDoctorLoginFormFields()
              else
                ...buildPracticeLoginFormFields(),
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

List<Widget> buildDoctorLoginFormFields() {
  final DoctorLoginController doctorLoginController =
      Get.find<DoctorLoginController>();

  return <Widget>[
    CustomTextField(
      textEditingController: doctorLoginController.emailController,
      focusNode: doctorLoginController.emailFocusNode,
      onSubmitted: (_) => doctorLoginController.submittedEmail(),
      labelText: 'Doctor E-Mail'.tr,
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
  ];
}

List<Widget> buildPracticeLoginFormFields() {
  final PracticeLoginController practiceLoginController =
      Get.find<PracticeLoginController>();

  return <Widget>[
    CustomTextField(
      textEditingController: practiceLoginController.emailController,
      focusNode: practiceLoginController.emailFocusNode,
      onSubmitted: (_) => practiceLoginController.submittedEmail(),
      labelText: 'Practice E-Mail'.tr,
      textInputType: TextInputType.emailAddress,
      prefixIcon: Icons.email,
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: practiceLoginController.passwordController,
      focusNode: practiceLoginController.passwordFocusNode,
      onSubmitted: practiceLoginController.loginController.isLoading.value
          ? (_) {}
          : (_) => practiceLoginController.submitLoginData(),
      labelText: 'Password'.tr,
      textInputType: TextInputType.visiblePassword,
      prefixIcon: Icons.password,
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    Obx(
      () => FilledButton.icon(
        icon: const Icon(Icons.login),
        onPressed: practiceLoginController.loginController.isLoading.value
            ? null
            : practiceLoginController.submitLoginData,
        label: Text('Login'.tr),
      ),
    ),
  ];
}
