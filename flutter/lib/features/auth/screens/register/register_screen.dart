import 'package:dermascan/app/app_theme.dart';
import 'package:dermascan/core/enums.dart';
import 'package:dermascan/core/models/check_criteria.dart';
import 'package:dermascan/core/widgets/custom_icon.dart';
import 'package:dermascan/core/widgets/custom_text_field.dart';
import 'package:dermascan/features/auth/controller/register/doctor_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/practice_register_controller.dart';
import 'package:dermascan/features/auth/controller/register/register_controller.dart';
import 'package:dermascan/translations/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.scaffoldPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const CustomIcon(iconData: Icons.app_registration),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                TrKeys.auth.joinDermascan.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Obx(() {
                if (controller.currentSelectedAuthOption.value ==
                    AuthOption.doctor) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: buildDoctorRegisterFormFields(context),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: buildPracticeRegisterFormFields(context),
                  );
                }
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

  final OutlineInputBorder noBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    borderSide: BorderSide.none,
  );

  return <Widget>[
    CustomTextField(
      textEditingController: doctorRegisterController.nameController,
      focusNode: doctorRegisterController.nameFocusNode,
      onSubmitted: (_) => doctorRegisterController.submittedName(),
      labelText: TrKeys.common.fullName.tr,
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
            decoration: InputDecoration(
              border: noBorder,
              enabledBorder: noBorder,
              focusedBorder: noBorder,
              labelText: TrKeys.common.dateOfBirth.tr,
              prefixIcon: const Icon(Icons.calendar_month),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: DropdownButtonFormField<Gender>(
            isExpanded: true,
            initialValue: doctorRegisterController.selectedGender,
            decoration: InputDecoration(
              border: noBorder,
              enabledBorder: noBorder,
              focusedBorder: noBorder,
              labelText: TrKeys.common.gender.tr,
              prefixIcon: const Icon(Icons.wc_outlined),
            ),
            items: Gender.values.map((Gender g) {
              return DropdownMenuItem<Gender>(
                value: g,
                child: Text(
                  _genderTranslationKey(g).tr,
                  overflow: TextOverflow.ellipsis,
                ),
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
      labelText: TrKeys.common.email.tr,
      prefixIcon: Icons.email,
      textInputType: TextInputType.emailAddress,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.correctlyFormatted.tr,
          criteriaState: doctorRegisterController.isValidEmail,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorRegisterController.passwordController,
      focusNode: doctorRegisterController.passwordFocusNode,
      onSubmitted: (_) => doctorRegisterController.submittedPassword(),
      labelText: TrKeys.common.password.tr,
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.minLength8.tr,
          criteriaState: doctorRegisterController.hasMinLength,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsUppercase.tr,
          criteriaState: doctorRegisterController.hasUppercase,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsLowercase.tr,
          criteriaState: doctorRegisterController.hasLowercase,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsDigit.tr,
          criteriaState: doctorRegisterController.hasDigits,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsSpecialChar.tr,
          criteriaState: doctorRegisterController.hasSpecialCharacters,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: doctorRegisterController.confirmPasswordController,
      focusNode: doctorRegisterController.confirmPasswordFocusNode,
      onSubmitted: (_) => doctorRegisterController.submitRegisterData(),
      labelText: TrKeys.auth.confirmPassword.tr,
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.passwordsMatch.tr,
          criteriaState: doctorRegisterController.passwordsMatch,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    FilledButton.icon(
      icon: const Icon(Icons.app_registration),
      onPressed: doctorRegisterController.submitRegisterData,
      label: Text(TrKeys.auth.register.tr),
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
      labelText: TrKeys.common.name.tr,
      prefixIcon: Icons.person,
      textInputType: TextInputType.name,
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: practiceRegisterController.emailController,
      focusNode: practiceRegisterController.emailFocusNode,
      onSubmitted: (_) => practiceRegisterController.submittedEmail(),
      labelText: TrKeys.common.email.tr,
      prefixIcon: Icons.email,
      textInputType: TextInputType.emailAddress,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.correctlyFormatted.tr,
          criteriaState: practiceRegisterController.isValidEmail,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController: practiceRegisterController.passwordController,
      focusNode: practiceRegisterController.passwordFocusNode,
      onSubmitted: (_) => practiceRegisterController.submittedPassword(),
      labelText: TrKeys.common.password.tr,
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.minLength8.tr,
          criteriaState: practiceRegisterController.hasMinLength,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsUppercase.tr,
          criteriaState: practiceRegisterController.hasUppercase,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsLowercase.tr,
          criteriaState: practiceRegisterController.hasLowercase,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsDigit.tr,
          criteriaState: practiceRegisterController.hasDigits,
        ),
        CheckCriteria(
          criteriaName: TrKeys.auth.containsSpecialChar.tr,
          criteriaState: practiceRegisterController.hasSpecialCharacters,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceMedium),
    CustomTextField(
      textEditingController:
          practiceRegisterController.confirmPasswordController,
      focusNode: practiceRegisterController.confirmPasswordFocusNode,
      onSubmitted: (_) => practiceRegisterController.submitRegisterData(),
      labelText: TrKeys.auth.confirmPassword.tr,
      prefixIcon: Icons.password,
      textInputType: TextInputType.visiblePassword,
      checkCriteria: <CheckCriteria>[
        CheckCriteria(
          criteriaName: TrKeys.auth.passwordsMatch.tr,
          criteriaState: practiceRegisterController.passwordsMatch,
        ),
      ],
    ),
    const SizedBox(height: AppTheme.spaceLarge),
    FilledButton.icon(
      icon: const Icon(Icons.app_registration),
      onPressed: practiceRegisterController.submitRegisterData,
      label: Text(TrKeys.auth.register.tr),
    ),
  ];
}

String _genderTranslationKey(Gender gender) {
  switch (gender) {
    case Gender.male:
      return TrKeys.common.male;
    case Gender.female:
      return TrKeys.common.female;
    case Gender.divers:
      return TrKeys.common.divers;
    case Gender.undefined:
      return TrKeys.common.undefined;
  }
}
