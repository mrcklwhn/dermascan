import 'package:dermascan/features/auth/controller/register/practice_register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PracticeRegisterForm extends StatelessWidget {
  PracticeRegisterForm({super.key});

  final PracticeRegisterController practiceRegisterController =
      Get.find<PracticeRegisterController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        TextField(
          controller: practiceRegisterController.nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Name',
            prefixIcon: Icon(Icons.local_hospital_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: practiceRegisterController.emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'E-Mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            obscureText: practiceRegisterController.passwordIsObscure.value,
            controller: practiceRegisterController.passwordController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: practiceRegisterController.changePasswordObscurity,
                icon: Icon(
                  practiceRegisterController.passwordIsObscure.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: <Widget>[
            _buildPasswordCriteriaRow(
              text: 'At least 8 characters',
              isValid: practiceRegisterController.hasMinLength,
            ),
            _buildPasswordCriteriaRow(
              text: 'Uppercase letter',
              isValid: practiceRegisterController.hasUppercase,
            ),
            _buildPasswordCriteriaRow(
              text: 'Lowercase letter',
              isValid: practiceRegisterController.hasLowercase,
            ),
            _buildPasswordCriteriaRow(
              text: 'Number',
              isValid: practiceRegisterController.hasDigits,
            ),
            _buildPasswordCriteriaRow(
              text: 'Special character',
              isValid: practiceRegisterController.hasSpecialCharacters,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            obscureText: practiceRegisterController.passwordIsObscure.value,
            controller: practiceRegisterController.confirmPasswordController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildPasswordCriteriaRow(
          text: 'Passwords match',
          isValid: practiceRegisterController.passwordsMatch,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() {
            return FilledButton(
              onPressed:
                  practiceRegisterController.registerController.isLoading.value
                  ? null
                  : practiceRegisterController.submitRegisterData,
              child: const Text('Register Practice'),
            );
          }),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPasswordCriteriaRow({
    required String text,
    required Rx<bool> isValid,
  }) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: <Widget>[
            Icon(
              isValid.value
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: isValid.value ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isValid.value ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
