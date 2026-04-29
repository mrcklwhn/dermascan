import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/app/enums.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/register/doctor_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/practice_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

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
              const CustomIcon(iconData: Icons.app_registration),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Join Dermascan!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              SegmentedButton<AuthOption>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<AuthOption>>[
                  ButtonSegment<AuthOption>(
                    value: AuthOption.doctor,
                    label: Text('Doctor'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                  ButtonSegment<AuthOption>(
                    value: AuthOption.practice,
                    label: Text('Practice'),
                    icon: Icon(Icons.business_outlined),
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
                ...buildDoctorRegisterFormFields(context)
              else
                ...buildPracticeRegisterFormFields(context),
              const SizedBox(height: AppTheme.spaceMedium),
              Obx(() {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.login),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.navigateBackToLogin,
                  label: const Text('Login'),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> buildDoctorRegisterFormFields(BuildContext context) {
  final DoctorRegisterController doctorRegisterController =
      Get.find<DoctorRegisterController>();

  return <Widget>[
    CustomTextField(
      textEditingController: doctorRegisterController.nameController,
      focusNode: doctorRegisterController.nameFocusNode,
      onSubmitted: (_) => doctorRegisterController.submittedName(),
      labelText: 'Full Name',
      prefixIcon: Icons.person,
      textInputType: TextInputType.name,
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: doctorRegisterController.birthdayController,
            readOnly: true,
            onTap: () => doctorRegisterController.selectDate(context),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.calendar_month),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: DropdownButtonFormField<Gender>(
            initialValue: doctorRegisterController.selectedGender,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: Gender.values.map((Gender g) {
              return DropdownMenuItem<Gender>(
                value: g,
                child: Text(g.name[0].toUpperCase() + g.name.substring(1)),
              );
            }).toList(),
            onChanged: (Gender? newValue) {
              doctorRegisterController.selectedGender = newValue;
            },
          ),
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorRegisterController.emailController,
      focusNode: doctorRegisterController.emailFocusNode,
      onSubmitted: (_) => doctorRegisterController.submittedEmail(),
      labelText: 'E-Mail',
      prefixIcon: Icons.email,
      textInputType: TextInputType.emailAddress,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Correctly formatted',
          criteriaState: doctorRegisterController.isValidEmail,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorRegisterController.passwordController,
      focusNode: doctorRegisterController.passwordFocusNode,
      onSubmitted: (_) => doctorRegisterController.submittedPassword(),
      labelText: 'Password',
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Contains at least 8 characters',
          criteriaState: doctorRegisterController.hasMinLength,
        ),
        CheckCriteria(
          criteriaName: 'Contains an uppercase letter',
          criteriaState: doctorRegisterController.hasUppercase,
        ),
        CheckCriteria(
          criteriaName: 'Contains a lowercase letter',
          criteriaState: doctorRegisterController.hasLowercase,
        ),
        CheckCriteria(
          criteriaName: 'Contains a digit',
          criteriaState: doctorRegisterController.hasDigits,
        ),
        CheckCriteria(
          criteriaName: 'Contains special character',
          criteriaState: doctorRegisterController.hasSpecialCharacters,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorRegisterController.confirmPasswordController,
      focusNode: doctorRegisterController.confirmPasswordFocusNode,
      onSubmitted: doctorRegisterController.registerController.isLoading.value
          ? (_) {}
          : (_) => doctorRegisterController.submitRegisterData(),
      labelText: 'Confirm Password',
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Passwords match',
          criteriaState: doctorRegisterController.passwordsMatch,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    FilledButton.icon(
      icon: const Icon(Icons.app_registration),
      onPressed: doctorRegisterController.registerController.isLoading.value
          ? null
          : doctorRegisterController.submitRegisterData,
      label: const Text('Register'),
    ),
  ];
}

List<Widget> buildPracticeRegisterFormFields(BuildContext context) {
  final PracticeRegisterController practiceRegisterController =
      Get.find<PracticeRegisterController>();

  return <Widget>[
    CustomTextField(
      textEditingController: practiceRegisterController.nameController,
      focusNode: practiceRegisterController.nameFocusNode,
      onSubmitted: (_) => practiceRegisterController.submittedName(),
      labelText: 'Name',
      prefixIcon: Icons.person,
      textInputType: TextInputType.name,
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: practiceRegisterController.emailController,
      focusNode: practiceRegisterController.emailFocusNode,
      onSubmitted: (_) => practiceRegisterController.submittedEmail(),
      labelText: 'E-Mail',
      prefixIcon: Icons.email,
      textInputType: TextInputType.emailAddress,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Correctly formatted',
          criteriaState: practiceRegisterController.isValidEmail,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: practiceRegisterController.passwordController,
      focusNode: practiceRegisterController.passwordFocusNode,
      onSubmitted: (_) => practiceRegisterController.submittedPassword(),
      labelText: 'Password',
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Contains at least 8 characters',
          criteriaState: practiceRegisterController.hasMinLength,
        ),
        CheckCriteria(
          criteriaName: 'Contains an uppercase letter',
          criteriaState: practiceRegisterController.hasUppercase,
        ),
        CheckCriteria(
          criteriaName: 'Contains a lowercase letter',
          criteriaState: practiceRegisterController.hasLowercase,
        ),
        CheckCriteria(
          criteriaName: 'Contains a digit',
          criteriaState: practiceRegisterController.hasDigits,
        ),
        CheckCriteria(
          criteriaName: 'Contains special character',
          criteriaState: practiceRegisterController.hasSpecialCharacters,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController:
          practiceRegisterController.confirmPasswordController,
      focusNode: practiceRegisterController.confirmPasswordFocusNode,
      onSubmitted: practiceRegisterController.registerController.isLoading.value
          ? (_) {}
          : (_) => practiceRegisterController.submitRegisterData(),
      labelText: 'Confirm Password',
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: 'Passwords match',
          criteriaState: practiceRegisterController.passwordsMatch,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    FilledButton.icon(
      icon: const Icon(Icons.app_registration),
      onPressed: practiceRegisterController.registerController.isLoading.value
          ? null
          : practiceRegisterController.submitRegisterData,
      label: const Text('Register'),
    ),
  ];
}
